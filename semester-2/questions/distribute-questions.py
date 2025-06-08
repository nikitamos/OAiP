#!/usr/bin/python3

# This script distributes the questions listed in file `question-list.txt`
# into 5 groups and for each group produces a `.tex` file containing
# sections titled according to given questions.
# Additionally, it emits an `all.tex` file that `\include`s
# all the files mentioned above.
#
# The number of questions in each group is passed as a command-line argument.

from itertools import islice
from typing import Iterable
from sys import argv

def write_file(question: Iterable[str], filename: str):
    with open(filename, 'w') as f:
        for q in question:
            print('\\section{%s}' % q, file=f)

with open('question-list.txt') as f:
    questions = [x.strip().removesuffix('.') for x in f.readlines()]

answers = ''


if __name__ == '__main__':
    begin = 0
    for g in map(int, argv[1:6]):
        filename = f'{begin+1}-{begin+g}.tex'
        answers += '\\include{questions/%s}\n' % filename
        write_file(islice(questions, begin, begin + g), filename)
        begin += g

    with open('all.tex', 'w') as f:
        f.write(answers)