import pandas as pd
from sklearn import linear_model

def regressionOnAll(df):
    cols = []
    for c in range(df.shape[1]):
        cols.append(str(c))
    df.columns = cols
    df = df.dropna()
    reg = linear_model.LinearRegression()
    res = []
    for c in range(df.shape[1]):
        reglist = []
        for d in range(df.shape[1]):
            if d is not c:
                reglist.append(str(d))
        reg.fit(df[reglist], df[str(c)])
        res.append([c, reg.intercept_, reg.coef_])
    return res

def get_stats(df, intent):
    if intent == "median":
        return "Medians:\n\b", df.median()
    if intent == "mean":
        return "Means:\n\b", df.mean()
    if intent == "mode":
        return "Modes:\n\b", df.mode()
    if intent == "deviation":
        return "Standart Deviaitons:\n\b", df.std()
    if intent == "quantile":
        return "0.25 / 0.75 Quantiles:\n\b", df.quantile([0.25, 0.75])
    if intent == "regression":
        return "Regression On All Column:\n\b", regressionOnAll(df)