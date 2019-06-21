# -*- coding: utf-8 -*-
"""
Created on Sat Jun  1 22:04:49 2019

@author: james

Parser Structure:
    find [
            parse word
            if ':'
                parse word
                ]
                relplace '[]' with '{}'
            else if ','
                parse word
                ','
                etc
        
"""

import re
import json

def parse_inst(inst_str):
    lines = inst_str.split('\n')
    inst_dict = {}
    for line in lines:
        line = line.strip()
        key, val = parse_dict(line)
        inst_dict[key] = val
    return inst_dict

def parse_dict(inst_str):
    head, tail = parse_atom(inst_str)
    return head, parse_word(tail[1:], parent=None)

def parse_word(word, parent):
    word = word.strip()
    if word == '':
        return []
    if word[0] == '[':
        # empty list
        if word[1] == ']':
            return []
        result = []
        list_inner = parse_list(word[1:])
        # List is Python dictionary
        if not list_inner['is_list']:
            result = {list_inner['head']: parse_word(list_inner['tail'], parent)}
        else:
            result = [list_inner['head']]
            result.extend(parse_word(list_inner['tail'], []))
        if parent:
            parent.append(result)
            return parent
        else:
            return result
    elif word[0]  == ']':
        return parent
    elif word[0] == ',':
        return parse_word(word[1:], parent)
    else:
        head, tail = parse_atom(word)
        if (not parent) and parent != []:
            return head
        else:
            if tail[0:2] == '^^':
                parent.append({head: parse_word(tail[2:], parent)})
                return parent
            parent.append(head)
            print(parent)
            return parse_word(tail, parent)

def parse_list(list_inner):
    head, tail = parse_atom(list_inner)
    result = {'head': head}
    if tail[0] == ':':
        result['is_list'] = False
        result['tail'] = tail[1:]
    elif tail[0:2] == '^^':
        result['is_list'] = False
        result['tail'] = (tail[2:])
    elif tail[0] == ',':
        result['is_list'] = True
        result['tail'] = tail[1:]
    return result

def parse_atom(in_str):
    word_regex = re.compile(r'(\([a-zA-Z0-9_]*,[a-zA-Z0-9_]*\))|([a-zA-Z0-9_]*)')
    head = word_regex.match(in_str).group()
    tail = in_str.replace(head, '')
    return (head, tail)

if __name__ == '__main__':
    with open('inst_test.txt') as f:
        inst_str = f.read()
    match = parse_inst(inst_str)