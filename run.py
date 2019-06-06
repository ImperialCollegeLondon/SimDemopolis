'''
Automatically run SimDemopolis, parse the output, analyse and plot the data.
'''

import os
import shutil
import subprocess
import shlex
import pprint
import re
import json
import matplotlib.pyplot as plt
import numpy as np
import networkx as nx

"""
Runs the SimDemopolis Prolog experiment suite, and returns the results
"""

# TODO: put most of this in classes 

def parse_institution(inst_str):
    inst_str = inst_str.strip(' \n')
    inst_str = parse_pairs(inst_str)
    inst_str = inst_str.replace('(', '[')
    inst_str = inst_str.replace(')', ']')
    lines = inst_str.split('\n')
    inst_dict = {}
    for line in lines:
        line = line.strip()
        key, val =  parse_dict(line)
        inst_dict[key] = val
    return inst_dict

"""
Allow (key, value) pairs to be parsed more easily by converting to key^^value
This prevents confusion with lists in parentheses
"""
def parse_pairs(inst_str):
    output_str = re.sub(r'\(([a-zA-Z0-9_]+),([a-zA-Z0-9_]+)\)',
           r'\1^^\2',
           inst_str)
    return output_str

def parse_dict(inst_str):
    head, tail = splice_atom(inst_str)
    return head, parse_term(tail[1:])[0]

def parse_term(word):
    word = word.strip()
    # Empty String
    if word == '':
        return None, ''
    if word[0] == '[':
        # empty list
        if word[1] == ']':
            if len(word) >=2:
                return [], word[2:]
            else:
                return [], ''
        """# List maps to Python dictionary
        if not is_list(word[1:]):
            return pl_list2py_dict(word)
        # List maps to Python list
        else:"""
        return parse_list(word)
    # word is an atom
    else:
        return splice_atom(word)
# checks to see if an atom points to another term
def is_pointer(head, tail):
    if tail[0:2] == '^^':
        return True
    else:
        return False

# atom pointing to a term
def parse_dict2(key, val):
    output = {}
    rest = ''
    val = val.strip()
    # dict value is a list
    if val[0] == '[':
        val_list, rest = parse_list(val)
        output[key] = val_list
    # dict value is an atom
    else:
        val_atom, rest = splice_atom(val)
        output[key] = val_atom
    return output, rest

def parse_list(list_str):
    # Remove opening '['
    list_str = list_str[1:]
    output = []
    while(True):
        if list_str == '' or list_str == ']':
            return output, ''
        elif list_str[0] == '[':
            inner_list, list_str = parse_list(list_str)
            output.append(inner_list)
        elif list_str[0] == ']':
            # list_str slice removes trailing ']'
            return output, list_str[1:]
        else:
            head, tail = splice_atom(list_str)
            if is_pointer(head, tail):
                head, tail = parse_dict2(head, tail[2:])
            output.append(head)
            # remove trailing ',' or ']'
            if tail[0] == ',':
                list_str = tail[1:]
            else:
                list_str = tail

def splice_atom(in_str):
    word_regex = re.compile(r'([a-zA-Z0-9_\.]*)')
    head = word_regex.match(in_str).group()
    tail = in_str.replace(head, '', 1)
    return (head, tail)

def has_voted(pp_str):
    voted_match = re.search(r'ra_vote: ((?:True)|(?:False))', pp_str)
    if voted_match.group(1) == 'True':
        return True
    else:
        return False

def pp2dict(pp_str):
    #print(pp_str)
    # List of rounds of role assignment
    ra_rounds = pp_str.split("NEW ROUND\n")
    # First list item is always an institution
    output = {'Institution_Start':parse_institution(ra_rounds.pop(0))}
    
    tick_regex = re.compile(r'\[tick,(\d+)\]')
    for ra_round in ra_rounds:
        tick = tick_regex.search(ra_round).group(1)
        vote_successful = re.search(r'ra_vote: ((?:True)|(?:False))', ra_round).group(1)
        agents_sep_start = 'Begin Agent Inspection\n'
        agents_start = ra_round.find(agents_sep_start) + len(agents_sep_start)
        agents_sep_end = '\nEnd Agent Inspection'
        agents_end = ra_round.find(agents_sep_end)
        agents_str = ra_round[agents_start:agents_end]
        tick_key = 'tick{}'.format(tick)
        # Separate each agent from the agent-containing string
        agents_list = []
        while(True):
            agents_str = agents_str.strip()            
            if agents_str == "":
                break
            else:
                agent_ind = agents_str.find('agent', 6)
                if agent_ind != -1:
                    agent_str = agents_str[0:agent_ind]
                    agents_str = agents_str[agent_ind:]
                else:
                    agent_str = agents_str
                    agents_str = ""
                agent_dict = parse_institution(agent_str)
                agents_list.append(agent_dict)        
        output[tick_key] = {'ra_vote':vote_successful,'agents':agents_list}
    
    # Extract final institution state after rounds are done
    inst_final_ind = ra_rounds[-1].find('inst')
    final_inst_str = ra_rounds[-1][inst_final_ind:]
    output['Institution_End'] = parse_institution(final_inst_str)
    return output

class AnalyzeNetwork():
    def plot_graph(self, sn_dict, file_name='', show=True):
        G = nx.json_graph.node_link_graph(sn_dict, False)
        nx.draw(G, with_labels=True, node_size=600)
        if file_name:
            plt.savefig(file_name)
        
        if show:
            plt.show()
        
    def sd2nx(self, sd_dict):
        nx_dict = {'nodes':[], 'links':[]}
        # Extract irst tick (all that is needed for social network)
        agent_list = sd_dict['tick1']['agents']
        for agent in agent_list:
            agent_name = agent['agent']
            nx_dict['nodes'].append({'id':agent_name})
            for link in agent['social_network']:
                nx_dict['links'].append({
                        'source': agent_name,
                        'target': link})
        return nx_dict
    
    def nx2sd(self, nx_dict):
        agent_list = []
        sn_list = []
        details = {agent['id']:[] for agent in nx_dict['nodes']}
        for link in nx_dict['links']:
            details[link['source']].append(link['target'])
        for agent, sn in details.items():
            agent_list.append(agent)
            sn_list.append(sn)
        return agent_list, sn_list
            
"""
Test the text parsing functionality from a samle SimDemopolis output from a 
file
"""    
def test_parse():
    with open('Development/test_output.txt') as f:
        test_str = f.read()
        test_dict = pp2dict(test_str)
    with open('Development/test_json.json', 'w') as f:
        json.dump(test_dict, f)
    return test_dict
    
"""
 Write sample SimDemopolis output to file (for debugging)
"""
def create_test_output():
    (stdout, stderr) = simDemopolis(True, 10)
    with open('Development/test_output.txt', 'w') as f:
        f.write(stdout)
    print(stderr)

def test_graph():
    cp = CivicParticipation()
    cp.load_result()
    sd_dict = cp.result[0]
    an = AnalyzeNetwork()
    nx_dict = an.sd2nx(sd_dict)
    agent_list, sn_list = an.nx2sd(nx_dict)


class Experiment():
    def reset_dir(self):
        os.makedirs(self.root_dir, exist_ok=True)
        rounds_path = '{}/Rounds'.format(self.root_dir)
        os.makedirs(rounds_path, exist_ok=True)
        for file_object in os.listdir(rounds_path):
            inner_path = os.path.join(rounds_path, file_object)
            if os.path.isfile(inner_path):
                os.unlink(inner_path)
            else:
                shutil.rmtree(inner_path) 
    
    def load_result(self, file_name=''):
        if not file_name:
            file_name = os.path.join(self.root_dir, 'full_result.json')
        with open(file_name) as f:
            self.result = json.load(f)
    
    def run(self, rounds, ticks=10):
        expt_result = []
        for round_num in range(rounds):
            stdout, stderr = simDemopolis(True, ticks)
            
            round_path = os.path.join(self.root_dir, 'Rounds', str(round_num))
            os.makedirs(round_path, exist_ok=True)
            with open(os.path.join(round_path, 'raw_output.txt'), 'w') as f:
                f.write(stdout)
            # SimDemopolis tends to fail if a node isn't connected. This causes
            # this erroneous output to be ignored
            if stderr.find('ERROR:') != -1:
                print('Error in round {}: see log for details'.format(round_num))
                with open(os.path.join(round_path, 'error_log.txt'), 'w') as f:
                    f.write(stderr)
                continue
            
            round_dict = pp2dict(stdout)
            with open(os.path.join(round_path, 'result.json'), 'w') as f:
                json.dump(round_dict, f)
            an = AnalyzeNetwork()
            nx_dict = an.sd2nx(round_dict)
            an.plot_graph(nx_dict, os.path.join(round_path, 'graph.png'))
                
            expt_result.append(round_dict)
            
        with open(os.path.join(self.root_dir, 'full_result.json'), 'w') as f:
            json.dump(expt_result, f)
        self.result =  expt_result
        
    def __init__(self, root_dir, dir_reset=True):
        self.result = []
        self.root_dir = root_dir
        if dir_reset:
            self.reset_dir()

class Skiver(Experiment):
    def plot(self, filename, show=True):
        time_in_role = self.get_time_in_role()
        plt.boxplot(time_in_role, vert=False)
        plt.ylabel('Round Number')
        plt.xlabel('Time in Role')
        plt.savefig(os.path.join(self.root_dir,'time_in_role.eps'))
        
    def get_time_in_role(self):
        expt_result = self.result
        output = []
        for res in expt_result:
            tir_dicts = res['Institution_End']['timeinrole']
            # Each time-in-role item is of the form {'agent': 'val'}
            tir_list = [int(agent_tir.popitem()[1]) for agent_tir in tir_dicts]
            output.append(tir_list)
        return output
            
    def __init__(self, root_dir='Skiver', dir_reset=True):
        super().__init__(root_dir, dir_reset)

class CivicParticipation(Experiment):
        # TODO: make sure indicies are right
    def plot(self, filename, show=True):
        round_total = len(self.result)
        tick_total = len(self.result[0])-2
        im_mtrx = np.zeros((round_total, tick_total))
        for round_num in range(round_total):
            round_dict = self.result[round_num]
            for tick_num in range(tick_total):
                tick_key = "tick{}".format(tick_num + 1)
                vote_successful = round_dict[tick_key]['ra_vote']
                print(vote_successful)
                if vote_successful == 'True':
                    im_mtrx[round_num, tick_num] = 1.0
        ax = plt.axes()
        c = ax.pcolor(im_mtrx)
        print(im_mtrx)
        plt.title('Role Reassignment')
        plt.ylabel('round')
        plt.xlabel('tick')
        if show:
            plt.show()
        plt.savefig(filename)
            
   
    def __init__(self, root_dir='Civic-Participation', dir_reset=True):
        super().__init__(root_dir, dir_reset)

            
""" 
Run the SimDemopolis Prolog Queries, and return the stdout and stderr text
""" 
def simDemopolis(interactive, ticks):
    halt = ""
    if interactive:
        halt = "-t halt "
    sim_script = "swipl -s main.pl -g run {}--socnet small_world --ticks {}".format(halt, ticks)
    Output = subprocess.run(shlex.split(sim_script),
                            text=True,
                            capture_output=True)
    print(type(Output))
    return (Output.stdout, Output.stderr)     

if __name__ == "__main__":
    #pp = pprint.PrettyPrinter(indent=4)
    sk = Skiver()
    sk.load_result()
    sk.plot('Skiver/plot.png')
    #civic_participation.load_result()
    #civic_participation.plot('Civic-Participation/test.eps')
    #create_test_output()
    #test_graph()