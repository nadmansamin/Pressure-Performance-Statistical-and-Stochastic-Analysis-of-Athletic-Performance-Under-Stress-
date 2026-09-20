%% ========================================================================
%  clutch_ft_analysis.m
%
%  "Do Players Really 'Choke' Under Pressure?"
%  A Statistical Analysis of Clutch Free-Throw Performance (NBA, 2006-2016)
%
%  SINGLE-FILE MATLAB SCRIPT (script body + local functions at the bottom).
%  Requires the Statistics and Machine Learning Toolbox (ttest, signrank, corr).
%
%  RESEARCH QUESTION
%    Do players shoot free throws worse in "clutch" situations (close game,
%    late clock) than they do otherwise, or is the apparent "choke effect"
%    just statistical noise from small clutch sample sizes?
%
%  HYPOTHESES (per level of analysis)
%    H0: mean(Clutch FT%) - mean(Non-Clutch FT%) = 0
%    H1 (two-tailed): mean(Clutch FT%) - mean(Non-Clutch FT%) != 0
%    H1 (one-tailed "choke" test): mean(Clutch FT%) < mean(Non-Clutch FT%)
%
%  EXPECTED INPUT FILE (place in the same folder as this script, or edit
%  dataFile below): an .xlsx with columns, in this order:
%    1 Player | 2 Season | 3 Reg. Total Att | 4 Regular Season FT%
%    5 Reg. Clutch Att | 6 Reg. Season Clutch FT% | 7 Playoff Total Att
%    8 Playoff FT% | 9 Playoff Clutch Att | 10 Playoff Clutch FT%
%
%  IMPORTANT DATA NOTE
%    "Regular Season FT%" / "Playoff FT%" are TOTAL FT% for the season and
%    already include the clutch attempts inside them -- they are NOT a
%    clean "non-clutch" baseline as given. Section 3 below backs the
%    clutch makes/attempts back out of the season total so that the
%    "non-clutch" FT% used in every comparison is a truly independent
%    (non-overlapping) sample from the "clutch" FT%.
%% ========================================================================

clear; clc; close all;

%% ---------------------------- 0. SETTINGS ------------------------------
% Anchor all paths to the folder this script lives in (NOT MATLAB's current
% working folder, which can differ from the script's location depending on
% how you launched it -- that mismatch is what causes "unable to open file"
% errors when writing outputs).
scriptDir = fileparts(mfilename('fullpath'));
if isempty(scriptDir)
    scriptDir = pwd;   % fallback if run by pasting into the Command Window
end

dataFile     = fullfile(scriptDir, 'Starter_FT_Stats_2006_2016_2.xlsx');  % <-- edit if needed
minClutchAtt = 10;     % "reliable sample" threshold, in clutch FT attempts
alphaLevel   = 0.05;   % significance level for all hypothesis tests
outDir       = fullfile(scriptDir, 'figures');

if ~exist(outDir, 'dir')
    [ok, msg] = mkdir(outDir);
    if ~ok
        error('Could not create output folder "%s": %s', outDir, msg);
    end
end

if ~exist(dataFile, 'file')
    error(['Could not find "%s".\nPut the Excel file in the same folder as ' ...
           'this script, or edit the dataFile path at the top of the script.'], dataFile);
end

%% ---------------------------- 1. LOAD DATA -----------------------------
T = readtable(dataFile, 'VariableNamingRule', 'preserve', 'TextType', 'string');
T.Properties.VariableNames = {'Player','Season','RegTotAtt','RegFTpct', ...
    'RegClAtt','RegClFTpct','PoTotAtt','PoFTpct','PoClAtt','PoClFTpct'};

fprintf('Loaded %d player-season rows (%d unique players, seasons %s to %s)\n', ...
    height(T), numel(unique(T.Player)), T.Season(1), T.Season(end));

%% ---------------------------- 2. CLEAN DATA ----------------------------
% Rows with 0 clutch attempts store FT% as 0 -- that is a "no data"
% placeholder, not a real 0% performance. Convert those to NaN so they are
% correctly excluded (not counted as misses) from every statistic below.
T.RegClFTpct(T.RegClAtt == 0) = NaN;
T.PoClFTpct(T.PoClAtt == 0)   = NaN;
T.PoFTpct(T.PoTotAtt == 0)    = NaN;   % defensive; not present in this file

%% ------------------ 3. RECOVER A TRUE NON-CLUTCH FT% -------------------
% Back out exact makes from each percentage (pct * attempts is an integer
% in this dataset), then subtract clutch makes/attempts from the season
% total to get a non-clutch sample that does NOT overlap with the clutch
% sample used for comparison.
RegTotMakes  = round(T.RegFTpct .* T.RegTotAtt);
RegClMakes   = round(T.RegClFTpct .* T.RegClAtt);
RegClMakes(isnan(RegClMakes)) = 0;         % 0 clutch attempts -> 0 clutch makes
T.RegClMakes    = RegClMakes;
T.RegNonClAtt   = T.RegTotAtt - T.RegClAtt;
T.RegNonClMakes = RegTotMakes - RegClMakes;
T.RegNonClFTpct = T.RegNonClMakes ./ T.RegNonClAtt;
T.RegNonClFTpct(T.RegNonClAtt == 0) = NaN;

PoTotMakes   = round(T.PoFTpct .* T.PoTotAtt);
PoClMakes    = round(T.PoClFTpct .* T.PoClAtt);
PoClMakes(isnan(PoClMakes)) = 0;
T.PoClMakes    = PoClMakes;
T.PoNonClAtt   = T.PoTotAtt - T.PoClAtt;
T.PoNonClMakes = PoTotMakes - PoClMakes;
T.PoNonClFTpct = T.PoNonClMakes ./ T.PoNonClAtt;
T.PoNonClFTpct(T.PoNonClAtt == 0) = NaN;

% Per-row "clutch effect": positive = better in clutch, negative = "choke"
T.RegDiff = T.RegClFTpct - T.RegNonClFTpct;
T.PoDiff  = T.PoClFTpct  - T.PoNonClFTpct;

%% ------------------------ 4. DESCRIPTIVE STATS -------------------------
printDescriptives(T);

%% ---- 5. HYPOTHESIS TESTS: CLUTCH vs NON-CLUTCH FT% (ALL ROWS) ---------
fprintf('\n===== REGULAR SEASON: Clutch vs Non-Clutch FT%% (all player-seasons) =====\n');
runPairedTests(T.RegNonClFTpct, T.RegClFTpct, alphaLevel);

fprintf('\n===== PLAYOFFS: Clutch vs Non-Clutch FT%% (all player-seasons) =====\n');
runPairedTests(T.PoNonClFTpct, T.PoClFTpct, alphaLevel);

%% -------- 6. RELIABILITY-FILTERED TEST (min. clutch attempts) ---------
relIdx = T.RegClAtt >= minClutchAtt & ~isnan(T.RegDiff);
fprintf('\n===== REGULAR SEASON: Clutch vs Non-Clutch (>=%d clutch attempts, n=%d rows) =====\n', ...
    minClutchAtt, sum(relIdx));
runPairedTests(T.RegNonClFTpct(relIdx), T.RegClFTpct(relIdx), alphaLevel);

%% ------------------ 7. PLAYER-LEVEL (CAREER) ANALYSIS ------------------
% Pool every season per player (attempt-weighted, i.e. sum makes/attempts)
% so each player contributes exactly ONE data point -- this avoids treating
% repeated seasons from the same player as independent observations.
P  = aggregateByPlayer(T);
Pf = P(P.ClAtt >= minClutchAtt & P.NonClAtt > 0, :);   % reliable subset

fprintf('\n===== PLAYER-LEVEL (CAREER) ANALYSIS, n=%d players with >=%d career clutch attempts =====\n', ...
    height(Pf), minClutchAtt);
[pT_player, pW_player, meanDiff_player] = runPairedTests(Pf.NonClFTpct, Pf.ClFTpct, alphaLevel);

%% --------- 8. IS THE "CLUTCH EFFECT" JUST SMALL-SAMPLE NOISE? ----------
% If apparent "choking"/"clutch" is mostly statistical noise, the SIZE of
% the deviation (|Diff|) should shrink as career clutch attempts grow.
[rhoDir, pDir] = corr(Pf.ClAtt, Pf.Diff,      'Type', 'Spearman');
[rhoMag, pMag] = corr(Pf.ClAtt, abs(Pf.Diff), 'Type', 'Spearman');
fprintf('\nSpearman corr(clutch attempts, signed diff):   rho=%.3f, p=%.4g\n', rhoDir, pDir);
fprintf('Spearman corr(clutch attempts, |diff|):        rho=%.3f, p=%.4g\n', rhoMag, pMag);
if rhoMag < 0 && pMag < alphaLevel
    fprintf(['-> Interpretation: the magnitude of a player''s clutch deviation shrinks\n' ...
             '   as attempt volume grows, consistent with "choking" being largely small-\n' ...
             '   sample statistical noise rather than a stable individual trait.\n']);
end

%% ------------- 9. TOP "CLUTCH" AND TOP "CHOKE" CANDIDATES --------------
Pf = sortrows(Pf, 'Diff', 'descend');
fprintf('\nTop 10 CLUTCH performers (Clutch FT%% - Non-Clutch FT%%), min %d career clutch att:\n', minClutchAtt);
disp(Pf(1:10, {'Player','NonClFTpct','ClFTpct','Diff','ClAtt'}));

fprintf('Bottom 10 "CHOKE" candidates (largest negative diff), min %d career clutch att:\n', minClutchAtt);
disp(Pf(end-9:end, {'Player','NonClFTpct','ClFTpct','Diff','ClAtt'}));

writetable(Pf, fullfile(outDir, 'player_clutch_summary.csv'));

%% -------------------------- 10. TREND BY SEASON -------------------------
seasons = unique(T.Season, 'stable');
meanDiffBySeason = nan(numel(seasons), 1);
for i = 1:numel(seasons)
    idx = strcmp(T.Season, seasons(i));
    meanDiffBySeason(i) = mean(T.RegDiff(idx), 'omitnan');
end

%% ------------------------------ 11. FIGURES ------------------------------
makeFigures(T, Pf, meanDiffBySeason, seasons, outDir);

%% ---------------------------- 12. CONCLUSION -----------------------------
fprintf('\n===== CONCLUSION (based on the player-level career analysis) =====\n');
fprintf('Mean career Clutch FT%% - Non-Clutch FT%% = %.2f percentage points\n', meanDiff_player * 100);
if pT_player < alphaLevel && meanDiff_player < 0
    fprintf(['Result: statistically significant DROP in FT%% during clutch situations\n' ...
              '(paired t-test p=%.4g, Wilcoxon p=%.4g). This supports a real "choke" effect.\n'], ...
              pT_player, pW_player);
elseif pT_player < alphaLevel && meanDiff_player > 0
    fprintf(['Result: statistically significant INCREASE in FT%% during clutch situations\n' ...
              '(paired t-test p=%.4g, Wilcoxon p=%.4g). No evidence of choking here.\n'], ...
              pT_player, pW_player);
else
    fprintf(['Result: NO statistically significant difference between clutch and non-clutch\n' ...
              'FT%% (paired t-test p=%.4g, Wilcoxon p=%.4g). This does NOT support a real,\n' ...
              'systematic "choke" effect at the population level.\n'], pT_player, pW_player);
end
fprintf('\nAll figures and the player summary table were saved to the "%s" folder.\n', outDir);


%% ========================================================================
%                            LOCAL FUNCTIONS
%  (Local functions in a script file are supported in MATLAB R2016b+.)
%% ========================================================================

function printDescriptives(T)
% Prints mean/median/SD (in percentage points) for the four core FT% series.
    fprintf('\n----- Descriptive Statistics (percentage points) -----\n');
    fprintf('%-26s %8s %8s %8s %8s\n', 'Metric', 'Mean', 'Median', 'SD', 'N');
    printRow('Reg. Non-Clutch FT%', T.RegNonClFTpct);
    printRow('Reg. Clutch FT%',     T.RegClFTpct);
    printRow('Playoff Non-Clutch FT%', T.PoNonClFTpct);
    printRow('Playoff Clutch FT%',     T.PoClFTpct);
end

function printRow(name, v)
    v = v(~isnan(v));
    fprintf('%-26s %8.2f %8.2f %8.2f %8d\n', name, mean(v)*100, median(v)*100, std(v)*100, numel(v));
end

function [p_t, p_w, meanDiff] = runPairedTests(nonClutch, clutch, alphaLevel)
% Paired comparison of two equal-length FT% vectors (NaNs allowed/paired-
% dropped). Runs: paired t-test (two-tailed), a one-tailed "choke" test
% (clutch < non-clutch), the Wilcoxon signed-rank test, and Cohen's d.
    keep = ~isnan(nonClutch) & ~isnan(clutch);
    d = clutch(keep) - nonClutch(keep);
    n = numel(d);

    [h, p_t, ci, stats] = ttest(d, 0, 'Alpha', alphaLevel);           % two-tailed
    [~, p_choke]         = ttest(d, 0, 'Alpha', alphaLevel, 'Tail', 'left'); % H1: clutch < non-clutch
    meanDiff = mean(d);
    dz = meanDiff / std(d);   % Cohen's d for paired samples

    fprintf(['Paired t-test (two-tailed): n=%d, mean diff=%.2f pp, t(%d)=%.3f, p=%.4g,\n' ...
             '  95%% CI=[%.2f, %.2f] pp, Cohen''s d=%.3f -> %s\n'], ...
             n, meanDiff*100, stats.df, stats.tstat, p_t, ci(1)*100, ci(2)*100, dz, sigLabel(h));
    fprintf('One-tailed "choke" test (H1: clutch < non-clutch): p=%.4g -> %s\n', ...
             p_choke, sigLabel(p_choke < alphaLevel));

    [p_w, h_w] = signrank(d);
    fprintf('Wilcoxon signed-rank test (nonparametric check): p=%.4g -> %s\n', p_w, sigLabel(h_w));
end

function lbl = sigLabel(isSig)
    if isSig
        lbl = 'SIGNIFICANT';
    else
        lbl = 'not significant';
    end
end

function P = aggregateByPlayer(T)
% Pools all seasons for each player (sum of makes / sum of attempts) so
% every player contributes exactly one data point to the career analysis.
    [G, players] = findgroups(T.Player);

    ClAtt      = splitapply(@sum, T.RegClAtt,      G);
    ClMakes    = splitapply(@sum, T.RegClMakes,    G);
    NonClAtt   = splitapply(@sum, T.RegNonClAtt,   G);
    NonClMakes = splitapply(@sum, T.RegNonClMakes, G);

    ClFTpct    = ClMakes ./ ClAtt;
    NonClFTpct = NonClMakes ./ NonClAtt;
    Diff       = ClFTpct - NonClFTpct;

    P = table(players, ClAtt, ClFTpct, NonClAtt, NonClFTpct, Diff, ...
        'VariableNames', {'Player','ClAtt','ClFTpct','NonClAtt','NonClFTpct','Diff'});
end

function makeFigures(T, Pf, meanDiffBySeason, seasons, outDir)
% Produces and saves the full figure set for the report.

    % --- Fig 1: Histogram of the per-season clutch effect -----------------
    f1 = figure('Color','w');
    histogram(T.RegDiff*100, 30, 'FaceColor', [0.20 0.45 0.75]);
    hold on;
    xline(0, 'k--', 'LineWidth', 1.5);
    xline(mean(T.RegDiff,'omitnan')*100, 'r-', 'LineWidth', 1.5);
    xlabel('Clutch FT% - Non-Clutch FT% (percentage points)');
    ylabel('Number of player-seasons');
    title('Distribution of the Clutch Effect (Regular Season)');
    legend({'Player-seasons','No effect (0)','Sample mean'}, 'Location','best');
    saveas(f1, fullfile(outDir, 'fig1_histogram_diff.png'));

    % --- Fig 2: Non-clutch vs clutch FT% scatter, y = x reference ---------
    f2 = figure('Color','w');
    scatter(T.RegNonClFTpct*100, T.RegClFTpct*100, 18, 'filled', ...
        'MarkerFaceAlpha', 0.5, 'MarkerFaceColor', [0.20 0.45 0.75]);
    hold on;
    plot([40 100], [40 100], 'k--', 'LineWidth', 1.2);
    xlabel('Non-Clutch FT% (season)');
    ylabel('Clutch FT% (season)');
    title('Clutch vs Non-Clutch FT%: Points Below the Line = Worse in Clutch');
    axis([40 100 40 100]); axis square;
    saveas(f2, fullfile(outDir, 'fig2_scatter_clutch_vs_nonclutch.png'));

    % --- Fig 3: Paired boxplot ---------------------------------------------
    f3 = figure('Color','w');
    data = [T.RegNonClFTpct; T.RegClFTpct] * 100;
    grp  = [repmat({'Non-Clutch'}, height(T), 1); repmat({'Clutch'}, height(T), 1)];
    boxplot(data, grp);
    ylabel('FT%');
    title('Regular Season FT%: Non-Clutch vs Clutch');
    saveas(f3, fullfile(outDir, 'fig3_boxplot.png'));

    % --- Fig 4: Mean clutch effect by season (trend) -----------------------
    f4 = figure('Color','w');
    bar(categorical(seasons, seasons), meanDiffBySeason*100, 'FaceColor', [0.30 0.55 0.35]);
    ylabel('Mean Clutch FT% - Non-Clutch FT% (pp)');
    title('Mean Clutch Effect by Season');
    xtickangle(45);
    saveas(f4, fullfile(outDir, 'fig4_trend_by_season.png'));

    % --- Fig 5: Top clutch / bottom choke players (career, filtered) -------
    f5 = figure('Color','w', 'Position', [100 100 700 600]);
    top10 = Pf(1:10, :);
    bot10 = Pf(end-9:end, :);
    combo = [top10; bot10];
    barh(categorical(combo.Player, flip(combo.Player)), combo.Diff*100, ...
        'FaceColor', [0.65 0.35 0.35]);
    xlabel('Clutch FT% - Non-Clutch FT% (career, pp)');
    title(sprintf('Most "Clutch" and Most "Choke" Players (min. %d career clutch attempts)', ...
        min(Pf.ClAtt)));
    saveas(f5, fullfile(outDir, 'fig5_top_bottom_players.png'));

    % --- Fig 6: Clutch attempt volume vs |clutch effect| -------------------
    f6 = figure('Color','w');
    scatter(Pf.ClAtt, abs(Pf.Diff)*100, 25, 'filled', ...
        'MarkerFaceColor', [0.55 0.35 0.65], 'MarkerFaceAlpha', 0.6);
    hold on;
    pfit = polyfit(Pf.ClAtt, abs(Pf.Diff)*100, 1);
    xx = linspace(min(Pf.ClAtt), max(Pf.ClAtt), 50);
    plot(xx, polyval(pfit, xx), 'k-', 'LineWidth', 1.5);
    xlabel('Career Clutch FT Attempts (sample size)');
    ylabel('|Clutch FT% - Non-Clutch FT%| (pp)');
    title('Does the Clutch Effect Shrink as Sample Size Grows?');
    saveas(f6, fullfile(outDir, 'fig6_volume_vs_magnitude.png'));
end