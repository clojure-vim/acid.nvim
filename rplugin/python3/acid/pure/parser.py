# encoding: utf-8
"""
Shameless copied from Peter Norvig's
(How to Write a (Lisp) Interpreter (in Python))

http://norvig.com/lispy.html

Slightly modified and adapted to read and return valid clojure code.
"""

Symbol = str
List   = list
Number = (int, float)


def tokenize(chars):
    "Convert a string of characters into a list of tokens."
    return chars.replace('(', ' ( ').replace(')', ' ) ').split()


def atom(token):
    "Numbers become numbers; every other token is a symbol."
    try: return int(token)
    except ValueError:
        try: return float(token)
        except ValueError:
            return Symbol(token)


def read_from_tokens(tokens):
    "Read an expression from a sequence of tokens."
    if len(tokens) == 0:
        raise SyntaxError('unexpected EOF while reading')
    token = tokens.pop(0)
    if '(' == token:
        L = []
        while tokens[0] != ')':
            L.append(read_from_tokens(tokens))
        tokens.pop(0) # pop off ')'
        return L
    elif ')' == token:
        raise SyntaxError('unexpected )')
    else:
        return atom(token)


def dump(tokens):
    form = []
    multi_forms = type(tokens[0]) == list
    for leaf in tokens:
        if type(leaf) == list:
            form.append(dump(leaf))
            if multi_forms:
                form.append('\n')
        else:
            form.append(leaf)
    if multi_forms:
        joined = "".join(map(str, form))
    else:
        joined = "({})".format(" ".join(map(str, form)))

    if " # " in joined:
        joined = ' #'.join(joined.split(' # '))

    return joined


def parse(program):
    "Read a clojure expression from a string."
    return read_from_tokens(tokenize(program))


def remove_comment(tokens):
    tks = list(tokens)
    if 'comment' in tks:
        tks.remove('comment')
    return tks

def transform(code, *token_fns):
    tks = parse(code)
    for fn in token_fns:
        tks = fn(tks)
    return dump(tks)
