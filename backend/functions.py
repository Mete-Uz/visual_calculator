import sympy as sm
from sympy.parsing.latex import parse_latex
from sympy import Symbol


def solve_matheq(latex_string, intent):
    expression = parse_latex(latex_string)
    symbols = expression.atoms(Symbol)
    symlist = []
    temp = ""
    flag = 0
    if str(expression)[0:2] == "Eq":
        flag = 1
        bstr = str(expression)[3::]
        for c in range(len(str(expression))):
            if str(expression)[- (c+2)] == ' ':
                break
            temp += str(expression)[- (c+2)]
    else:
        bstr = str(expression)
    temp = temp[::-1]
    indf = bstr.find('(')
    if bstr[0].islower() or bstr[0].isnumeric():
        indf = -1
    inde = bstr.find(',')
    if inde == -1:
        inde = len(bstr)
    body = bstr[indf + 1:inde]
    if flag == 1:
        body = "Eq(" + body + "," + temp + ")"
    for sym in symbols:
        symlist.append(Symbol(str(sym)))
    if intent == "solve":
        return sm.latex(expression.doit())
    if intent == "answer":
        return sm.latex(sm.solve(expression.doit()))
    if intent == "integrate":
        return sm.latex(sm.integrate(body, *symlist))
    if intent == "derivative":
        return sm.latex(sm.diff(body,*symlist))
    # if intent == "summation":
    #     return sm.latexsm.summation(expression, *symlist)
    if intent == "simplification":
        return sm.latex(sm.simplify(body))
    if intent == "factors":
        return sm.latex(sm.factor(body))
    if intent == "expansion":
        return sm.latex(sm.expand(body))
    return "An error has occurred, please try again."

if __name__ == '__main__':
    print(solve_matheq("3 x^{2}+5 x+1 + 2x = 5", "integrate"))