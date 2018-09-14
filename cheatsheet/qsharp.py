from pygments.lexer import RegexLexer, words, bygroups
from pygments.token import *

class QSharpLexer(RegexLexer):
    name      = 'Q#'
    aliases   = ['qsharp']
    filenames = ['*.qs']

    tokens = {
        'root': [
            (r'\n', Text),
            (r'\s+', Text),
            (r'//(.*?)\n', Comment.Single),
            (words((
                'body', 'adjoint', 'controlled', 'auto', 'new', 'using', 'borrowing'
            ), suffix=r'\b'), Keyword),
            (r'(operation|function)(\s+)', bygroups(Keyword, Text), 'function'),
            (words((
                'set', 'mutable', 'let'
            ), suffix = r'\b'), Keyword.Declaration),
            (r'(newtype)(\s+)', bygroups(Keyword.Declaration, Text), 'newtype'),
            (r'(open|namespace)(\s+)', bygroups(Keyword.Namespace, Text), 'namespace'),
            (words((
                'One', 'Zero', 'PauliX', 'PauliY', 'PauliZ', 'PauliI', 'true', 'false'
            ), suffix = r'\b'), Keyword.Constant),
            (words((
                'if', 'elif', 'else', 'fail', 'for', 'in', 'return', 'repeat', 'until', 'fixup'
            ), suffix = r'\b'), Keyword),
            (words((
                'M', 'H', 'CNOT', 'CCNOT', 'I', 'Measure', 'Message', 'Assert', 'AssertProb', 'Exp', 'ExpFrac', 'R', 'R1', 'RFrac', 'R1Frac', 'Random', 'Reset', 'ResetAll', 'Rx', 'Ry', 'Rz', 'S', 'SWAP', 'T', 'X', 'Y', 'Z', 'MultiX', 'Length'
            ), suffix = r'\b'), Name.Builtin),
            (words((
                'Int', 'Double', 'String', 'Bool', 'Qubit', 'Pauli', 'Result', 'Range'
            ), suffix = r'\b'), Keyword.Type),
            (r'('
                r'[()\[\]{}]|'
                r'[.=:;_]'
            r')', Punctuation),
            (r'('
                r'[+\-*/%^]|'
                r'!|'
                r'[&|]{2}|'
                r'[&|^<>~]{3}|'
                r'(==|!=|<|>|<=|>=)|'
                r'\.\.'
            r')', Operator),
            (r'(0|[1-9][0-9]*)', Number.Integer),
            (r'0x[0-9A-Fa-f]+', Number.Hex),
            (r'[0-9]\.[0-9]+([eE][0-9]+)?', Number.Float),
            (r'"(\"|[^"])*"', String.Double),
            (r'($)"(\"|[^"]|(\{[_a-zA-Z]\w*\}))*"', bygroups(String.Affix, String.Double, String.Interpol)),
            (r'[_a-zA-Z]\w*', Name)
        ],
        'function': [
            (r'[_a-zA-Z]\w*', Name.Function, '#pop')
        ],
        'namespace': [
            (r'([_a-zA-Z]\w*|\.)+', Name.Namespace, '#pop')
        ],
        'newtype': [
            (r'[_z-zA-Z]\*', Name.Class, '#pop')
        ]
    }
