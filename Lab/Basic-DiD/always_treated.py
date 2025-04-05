import numpy as np
import pandas as pd
import statsmodels.api as sm
import statsmodels.formula.api as smf

# Seed for reproducibility
np.random.seed(12345)

# Step 1: Generate 1000 workers
n_workers = 1000
ids = np.arange(1, n_workers + 1)

# Generate fixed effects from Uniform(0,5)
fe = np.random.uniform(0, 5, n_workers)

# Step 2: Define treatment based on fixed effects
median_fe = np.median(fe)
treat = (fe > median_fe).astype(int)

# Step 3: Generate data for two years (1990, 1991)
df = pd.DataFrame({
    'id': np.repeat(ids, 2),
    'year': np.tile([1990, 1991], n_workers),
    'fe': np.repeat(fe, 2),
    'treat': np.repeat(treat, 2)
})

df['post'] = (df['year'] == 1991).astype(int)

# Step 4: Potential outcomes Y0 and Y1
# Adding normally distributed errors
df['e'] = np.repeat(np.random.normal(size=n_workers), 2)
df['Y0'] = df['fe'] + df['e']
df['Y1'] = df['Y0'] + 5

# Step 5: Generate Y1_C for Constant Treatment Effects
df['Y1_C'] = np.where(df['post'] == 0, df['Y0'], df['Y0'] + 5)

# Step 6: Delta_C
df['Delta_C'] = df['Y1_C'] - df['Y0']

# Summarize Delta_C if treated and year == 1991
summary_delta_c = df.query('post == 1 & treat == 1')['Delta_C'].mean()
print('Mean Delta_C (Treated, Post):', summary_delta_c)

# Step 7: Earnings_C (Switching Equation for Constant TE)
df['earnings_C'] = np.where(df['treat'] == 1,
                            np.where(df['post'] == 0, df['Y0'], df['Y1']),
                            np.where(df['post'] == 0, df['Y0'] + 5, df['Y0'] + 5))

# Step 8: Run DiD regression with constant TE
model_constant = smf.ols('earnings_C ~ post * treat', data=df).fit(cov_type='HC1')
print(model_constant.summary())

# ---- Dynamic Treatment Effects ----

# Step 9: Generate Y1_D for Dynamic Treatment Effects
df['Y1_D'] = np.where(df['treat'] == 1,
                      np.where(df['post'] == 0, df['Y0'], df['Y0'] + 5),
                      np.where(df['post'] == 0, df['Y0'] + 5, df['Y0'] + 10))

# Step 10: Earnings_D (Switching Equation for Dynamic TE)
df['earnings_D'] = df['Y1_D']

# Step 11: Run DiD regression with dynamic TE
model_dynamic = smf.ols('earnings_D ~ post * treat', data=df).fit(cov_type='HC1')
print(model_dynamic.summary())
