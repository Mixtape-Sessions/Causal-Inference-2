#**********************************************************************
# na.py
# Description: illustrating a no anticipation violation with diff-in-diff
#**********************************************************************

import numpy as np
import pandas as pd
import statsmodels.formula.api as smf

np.random.seed(20200403)

# Create states and firms
states = np.repeat(np.arange(1, 41), 25)
firms = np.random.uniform(0, 5, len(states))

# Expand for years
data = pd.DataFrame({'state': states, 'firms': firms})
data = data.loc[data.index.repeat(4)].reset_index(drop=True)
data['year'] = np.tile(np.array([1990, 1991, 1992, 1993]), int(len(data)/4))
data['n'] = data.groupby(['state', 'firms']).cumcount() + 1

# Create id
data['id'] = data.groupby(['state', 'firms']).ngroup()

# Treatment group: upper half
data['group'] = (data['id'] >= 500).astype(int)

# Correct post-treatment indicator (no anticipation satisfied)
data['post'] = (data['year'] >= 1991).astype(int)

# Incorrect post-treatment indicator (no anticipation violated)
data['post_na'] = (data['year'] >= 1992).astype(int)

# Data generating process
data['e'] = np.random.normal(0, 1, len(data))
data['y0'] = data['firms'] + data['n'] + data['e']

# Constant treatment effect
data['y1_c'] = data['y0'] + np.where(data['year'] >= 1991, 10, 0)

# Dynamic treatment effect
data['y1_d'] = data['y0'] + np.select(
    [data['year'] == 1991, data['year'] == 1992, data['year'] == 1993],
    [10, 20, 30],
    default=0
)

# Treatment effects
data['delta_c'] = data['y1_c'] - data['y0']
data['delta_d'] = data['y1_d'] - data['y0']

print(data.loc[(data['year'] >= 1991) & (data['group'] == 1), ['delta_c', 'delta_d']].describe())

# Treatment indicator
data['d'] = ((data['year'] >= 1991) & (data['group'] == 1)).astype(int)

# Observed outcomes (switching equation)
data['y_c'] = np.where(data['d'] == 1, data['y1_c'], data['y0'])
data['y_d'] = np.where(data['d'] == 1, data['y1_d'], data['y0'])

# Aggregate causal parameters
att_c = data.loc[(data['year'] >= 1991) & (data['group'] == 1), 'delta_c'].mean()
att_d = data.loc[(data['year'] >= 1991) & (data['group'] == 1), 'delta_d'].mean()

print(f"ATT (constant): {att_c}")
print(f"ATT (dynamic): {att_d}")

# Correct specifications
print("\nCorrect specifications:")
model_c = smf.ols('y_c ~ group * post', data=data).fit(cov_type='HC1')
print(model_c.summary())

model_d = smf.ols('y_d ~ group * post', data=data).fit(cov_type='HC1')
print(model_d.summary())

# Incorrect specifications (NA violated)
print("\nIncorrect specifications (NA violated):")
data_na = data[data['year'] >= 1991]

model_c_na = smf.ols('y_c ~ group * post_na', data=data_na).fit(cov_type='HC1')
print(model_c_na.summary())

model_d_na = smf.ols('y_d ~ group * post_na', data=data_na).fit(cov_type='HC1')
print(model_d_na.summary())
