"""Verify data lineage and regenerate descriptive figures; does not fit R/SAS models.
Run: python scripts/verify_data.py (from any directory).
"""
from pathlib import Path
import json
import platform
import importlib.metadata
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis

ROOT = Path(__file__).resolve().parents[1]
RAW, PROCESSED = ROOT / 'data/raw', ROOT / 'data/processed'
RESULTS, FIGURES = ROOT / 'results', ROOT / 'figures'
RESULTS.mkdir(exist_ok=True)
FIGURES.mkdir(exist_ok=True)
harvest = pd.read_csv(RAW / 'G12.outcome.data.csv')
size = pd.read_csv(RAW / 'G12.size.data.csv')
soil = pd.read_csv(RAW / 'G12.soil.data.csv')
binary = pd.read_csv(PROCESSED / 'quality_binary.csv')
long = pd.read_csv(PROCESSED / 'longitudinal_data.csv')
complete = pd.read_csv(PROCESSED / 'time_data_clean.csv')
checks = {}
def check(name, condition):
    checks[name] = bool(condition)
    if not condition:
        raise AssertionError(name)

check('harvest_id_unique', harvest.ID.is_unique)
check('size_pear_id_unique', size.pear_id.is_unique)
check('soil_tree_id_unique', soil.tree_ID.is_unique)
check('harvest_quality_range', harvest.quality_idx.between(0, 100).all())
check('harvest_complete', not harvest.isna().any().any())
check('soil_complete', not soil.isna().any().any())
for label, frame in [('harvest', harvest), ('size', size), ('soil', soil)]:
    check(label + '_climate_levels', set(frame.climate) == {f'Scenario {i}' for i in range(1, 5)})
    check(label + '_species_levels', set(frame.species) == {'Conference', 'Doyenne'})
pd.testing.assert_frame_equal(harvest, binary[harvest.columns], check_dtype=False)
check('binary_threshold_55', np.array_equal(binary.quality_b, (harvest.quality_idx >= 55).astype(int)))
weeks = [f'week_{i}' for i in range(5, 25)]
ids = ['pear_id', 'tree_id', 'ecotr_id', 'species', 'climate']
expected_long = size.melt(id_vars=ids, value_vars=weeks, var_name='time', value_name='quality')
expected_long['time'] = expected_long.time.str.removeprefix('week_').astype(int)
def canonical(frame):
    return frame.sort_values(['pear_id', 'time']).reset_index(drop=True)
pd.testing.assert_frame_equal(canonical(expected_long), canonical(long), check_dtype=False, atol=1e-10, rtol=1e-10)
check('longitudinal_matches_raw_reshape', True)
complete_ids = size.loc[size[weeks].notna().all(axis=1), 'pear_id']
pd.testing.assert_frame_equal(canonical(expected_long[expected_long.pear_id.isin(complete_ids)]), canonical(complete), check_dtype=False, atol=1e-10, rtol=1e-10)
check('complete_case_export_matches_raw', True)
missing = size[weeks].isna().to_numpy()
check('dropout_monotone', (np.diff(missing.astype(int), axis=1) >= 0).all())
check('long_unique_pear_week', not long.duplicated(['pear_id','time']).any())
check('one_climate_per_harvest_ecotron', harvest.groupby(['location', 'ecotr_id']).climate.nunique().eq(1).all())
check('one_climate_per_growth_ecotron', size.groupby('ecotr_id').climate.nunique().eq(1).all())
keys = ['location', 'ecotr_id', 'tree_id']
counts = harvest.groupby(keys).size().rename('pears').reset_index()
joined = soil.merge(counts, on=keys, how='left', validate='one_to_one')
check('soil_harvest_full_join_coverage', joined.pears.notna().all() and len(joined) == len(soil) == len(counts))
joined.to_csv(RESULTS / 'soil-with-pear-counts.csv', index=False)

# Standardization matches R scale(): sample standard deviations (ddof=1).
features = [c for c in soil if c not in ['tree_ID', *keys, 'species', 'climate']]
x = soil[features].to_numpy(dtype=float)
z = (x - x.mean(axis=0)) / x.std(axis=0, ddof=1)
u, singular, vt = np.linalg.svd(z, full_matrices=False)
eigenvalues = singular ** 2 / (len(z) - 1)
ratios = eigenvalues / eigenvalues.sum()
check('pca_17_features', len(features) == 17)
check('pca_trace_17', np.isclose(eigenvalues.sum(), 17))
check('pca_first_components_match_report_rounding', np.array_equal(np.round(ratios[:3] * 100, 1), [19.5, 14.7, 14.5]))
pd.DataFrame({'component':np.arange(1,18), 'eigenvalue':eigenvalues, 'variance_fraction':ratios, 'cumulative_fraction':ratios.cumsum()}).to_csv(RESULTS / 'pca-variance.csv', index=False)
pd.DataFrame(vt.T, index=features, columns=[f'PC{i}' for i in range(1,18)]).to_csv(RESULTS / 'pca-loadings.csv', index_label='feature')
pd.DataFrame(u * singular, columns=[f'PC{i}' for i in range(1,18)]).assign(tree_ID=soil.tree_ID, climate=soil.climate).to_csv(RESULTS / 'pca-scores.csv', index=False)
predictors = joined[features + ['pears']].to_numpy(dtype=float)
predictors = (predictors-predictors.mean(0))/predictors.std(0,ddof=1)
lda = LinearDiscriminantAnalysis(solver='svd').fit(predictors, joined.climate)
ld = lda.transform(predictors)
check('lda_ratios_match_report_rounding', np.array_equal(np.round(lda.explained_variance_ratio_ * 100,1), [59.8,23.0,17.1]))
pd.DataFrame({'discriminant':['LD1','LD2','LD3'], 'discrimination_fraction':lda.explained_variance_ratio_}).to_csv(RESULTS / 'lda-variance.csv', index=False)
pd.DataFrame(ld, columns=['LD1','LD2','LD3']).assign(tree_ID=soil.tree_ID,climate=soil.climate).to_csv(RESULTS / 'lda-scores.csv', index=False)
# Export all coefficients. Signs may be reversed relative to MASS::lda without changing the solution.
pd.DataFrame(lda.scalings_, index=features+['pears'], columns=['LD1','LD2','LD3']).to_csv(RESULTS / 'lda-coefficients.csv', index_label='feature')

harvest.groupby(['climate','location','species']).quality_idx.agg(['size','mean','std','median','min','max']).to_csv(RESULTS / 'quality-subgroups.csv')
retention = long.groupby(['species','climate','time']).quality.agg(n_observed='count',n_scheduled='size',mean_size='mean').reset_index()
retention['retained_fraction'] = retention.n_observed / retention.n_scheduled
retention.to_csv(RESULTS / 'growth-and-retention.csv', index=False)

# Figure contract: static files for GitHub. Four climate categories use explicit
# blue/orange/olive/pink colors plus distinct markers; weekly views have 20 points.
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':11,'axes.spines.top':False,'axes.spines.right':False,'axes.labelcolor':'#263238','text.color':'#263238','figure.facecolor':'white'})
colors = ['#3176AD','#D57A24','#7A8638','#BF6287']
markers = ['o','s','^','D']
scenarios = [f'Scenario {i}' for i in range(1,5)]
def save(fig, name):
    fig.savefig(FIGURES / name, dpi=160, bbox_inches='tight', facecolor='white')
    plt.close(fig)
fig,axes=plt.subplots(1,2,figsize=(12,4.6),layout='constrained')
for ax,loc in zip(axes,['BE','FR']):
    arrays=[harvest.loc[(harvest.location==loc)&(harvest.climate==s),'quality_idx'] for s in scenarios]
    b=ax.boxplot(arrays,tick_labels=['1','2','3','4'],patch_artist=True,medianprops={'color':'#263238'})
    for box,color in zip(b['boxes'],colors):box.set_facecolor(color);box.set_alpha(.4)
    ax.set(title=f'{loc}: '+str(sum(map(len,arrays)))+' harvested pears',xlabel='Climate scenario',ylabel='Quality index (0–100)',ylim=(-3,103))
    ax.grid(axis='y',alpha=.18)
fig.suptitle('Harvest quality by climate and location',fontsize=16)
save(fig,'quality-distribution.png')
fig,axes=plt.subplots(1,2,figsize=(12,4.8),layout='constrained')
for s,c,m in zip(scenarios,colors,markers):
    means=long.loc[long.climate==s].groupby('time').quality.mean()
    axes[0].plot(means.index,means.values,label=s,color=c,marker=m,markevery=3,markersize=4)
for s,c,m in zip(['Conference','Doyenne'],colors,markers):
    means=long.loc[long.species==s].groupby('time').quality.mean()
    axes[1].plot(means.index,means.values,label=s,color=c,marker=m,markevery=3,markersize=4)
for ax,title in zip(axes,['By climate (one ecotron per scenario)','By pear variety']):
    ax.set(title=title,xlabel='Week',ylabel='Observed mean pear size (cm)',xticks=[5,10,15,20,24])
    ax.grid(alpha=.18);ax.legend(frameon=False)
fig.suptitle('Pear growth over weeks 5–24 | 192 pears at baseline',fontsize=15)
save(fig,'growth-trajectories.png')
fig,ax=plt.subplots(figsize=(8,4.3),layout='constrained')
for s,c,m in zip(['Conference','Doyenne'],colors,markers):
    q=long[long.species==s].groupby('time').quality.agg(['count','size'])
    ax.step(q.index,100*q['count']/q['size'],where='post',color=c,label=s,marker=m,markevery=3)
ax.set(title='Observed measurements by week and variety',xlabel='Week (192 pears scheduled at each visit)',ylabel='Measurements observed (%)',ylim=(0,105),xticks=[5,10,15,20,24])
ax.legend(frameon=False);ax.grid(alpha=.18);save(fig,'retention.png')
fig,axes=plt.subplots(1,2,figsize=(12,4.7),layout='constrained')
axes[0].bar(np.arange(1,18),100*ratios,color=colors[0],edgecolor='white')
axes[0].set(title='PCA variance explained',xlabel='Principal component',ylabel='Total variance (%)',xticks=[1,3,5,7,9,11,13,15,17])
for s,c,m in zip(scenarios,colors,markers):
    mask=soil.climate==s;axes[1].scatter((u*singular)[mask,0],(u*singular)[mask,1],label=s,color=c,marker=m,s=28,alpha=.8)
axes[1].set(title='PCA observation scores (96 trees)',xlabel=f'PC1 ({ratios[0]*100:.1f}%)',ylabel=f'PC2 ({ratios[1]*100:.1f}%)')
axes[1].legend(frameon=False,fontsize=9)
fig.suptitle('Soil structure | 17 standardized features',fontsize=15)
save(fig,'soil-pca.png')
fig,ax=plt.subplots(figsize=(8,4.6),layout='constrained')
for s,c,m in zip(scenarios,colors,markers):
    mask=soil.climate==s;ax.scatter(ld[mask,0],ld[mask,1],label=s,color=c,marker=m,s=32,alpha=.8)
ax.set(title='LDA fitted scores | 96 trees, 17 soil features and pear counts',xlabel='LD1',ylabel='LD2')
ax.legend(frameon=False);save(fig,'soil-lda.png')
summary = {'checks':checks,'harvest_rows':len(harvest),'harvest_ecotrons':len(harvest[['location','ecotr_id']].drop_duplicates()),'harvest_trees':len(counts),'harvest_mean_quality':harvest.quality_idx.mean(),'growth_pears':len(size),'scheduled_measurements':len(long),'observed_measurements':int(long.quality.notna().sum()),'missing_measurements':int(long.quality.isna().sum()),'complete_pears':int(len(complete_ids)),'week24_by_species':long[long.time==24].groupby('species').quality.count().to_dict(),'pca_first7_fraction':float(ratios[:7].sum()),'pca_first8_fraction':float(ratios[:8].sum()),'r_models_executed':False,'sas_models_executed':False,'python_version':platform.python_version(),'packages':{p:importlib.metadata.version(p) for p in ['numpy','pandas','matplotlib','scipy','scikit-learn']}}
(RESULTS / 'validation.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))
