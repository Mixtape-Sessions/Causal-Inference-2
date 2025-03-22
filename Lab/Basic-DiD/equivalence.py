import pandas as pd
import statsmodels.api as sm
import statsmodels.formula.api as smf

# Load data
url = "https://github.com/scunning1975/mixtape/raw/master/castle.dta"
df = pd.read_stata(url)

# Panel setup
df = df.sort_values(['sid', 'year'])

# Drop specific years
df = df[~df['effyear'].isin([2005, 2007, 2008, 2009])]

# Generate post variable
df['post'] = (df['year'] >= 2006).astype(int)

# Generate treat variable
df['treat'] = (df['effyear'] == 2006).astype(int)

# OLS regression with clustering on state
model1 = smf.ols("l_homicide ~ post * treat", data=df)
result1 = model1.fit(cov_type='cluster', cov_kwds={'groups': df['state']})
print("OLS regression with clustering:")
print(result1.summary())

# Manual DiD calculation
ey11 = df[(df['post'] == 1) & (df['treat'] == 1)]['l_homicide'].mean()
ey10 = df[(df['post'] == 0) & (df['treat'] == 1)]['l_homicide'].mean()
ey01 = df[(df['post'] == 1) & (df['treat'] == 0)]['l_homicide'].mean()
ey00 = df[(df['post'] == 0) & (df['treat'] == 0)]['l_homicide'].mean()

did = (ey11 - ey10) - (ey01 - ey00)
print("\nManual DiD estimate:")
print("DiD = {:.4f}".format(did))

# Weighted regression with clustering (like Cheng and Hoekstra)
model2 = smf.wls("l_homicide ~ post * treat", data=df, weights=df['popwt'])
result2 = model2.fit(cov_type='cluster', cov_kwds={'groups': df['state']})
print("\nWeighted regression with clustering:")
print(result2.summary())