'''
Automatically run SimDemopolis, parse the output, analyse and plot the data.
'''

import os
import shutil
import subprocess
import shlex
import pickle
import re
import json
import matplotlib.pyplot as plt
import numpy as np
import networkx as nx

"""
Runs the SimDemopolis Prolog experiment suite, and returns the results
"""

# -----------------------------------------------------------------------------
# Code for parsing the output of SimDemopolis. pp2dict() is the important
# fucuntion. This converts the output of SimDemopolis from a text string to a
# Python dictionary.
# -----------------------------------------------------------------------------

def parse_institution(inst_str):
    """Parse an institution string from SimDemopolis into a Python dictionary"""
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

def parse_pairs(inst_str):
    """
    Allows (key, value) pairs to be parsed more easily by converting to key^^value
    format. This prevents confusion with lists in parentheses.
    """
    output_str = re.sub(r'\(([a-zA-Z0-9_]+),([a-zA-Z0-9_]+)\)',
           r'\1^^\2',
           inst_str)
    return output_str

def parse_dict(inst_str):
    """ If a string begins with a "key: value" format, return the key and parsed 
    value as a tuple, for insertion into a dictionary.
    """
    head, tail = splice_atom(inst_str)
    return head, parse_term(tail[1:])[0]

def parse_term(word):
    """Parses a term at the beginning of a string, and detmines the 
    type of the term, parsing as neccessary.
    
    Returns
    -------
    (term, rest)
        Parsed term from the beginning of a list, and the rest as a string. 
        This can either be a list or a string.
    """
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

def is_pointer(head, tail):
    """Checks to see if an atom points to another term. Head is the atom
    at the start of the string. Pointers are of the form 'atom^^term.' Returns
    a boolean.
    """
    if tail[0:2] == '^^':
        return True
    else:
        return False

# atom pointing to a term
def parse_dict2(key, val):
    """If a string begins with an atom pointing to another term (key^^val), 
    convert the key^^val to a dictionary. val can either be an atom or a list.
    
    Returns
    -------
    (output, rest) : (dictionary, string)
        The parsed beginning of the string as a dictionary, and the rest as a 
        string.
    """
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
    """ Parses the list at the beginning of a string.
    
    Returns
    -------
    (output, rest) : (list, string)
        The parsed beginning of the string as a list, and the rest as a string.    
    """
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
    """Removes the atom at the beginning of a string
    
    :returns (head,tail): The atom at the beginning of in_str as a string and the 
    rest as a string
    :rtype: tuple"""
    word_regex = re.compile(r'([a-zA-Z0-9_\.\+-]*)')
    head = word_regex.match(in_str).group()
    tail = in_str.replace(head, '', 1)
    return (head, tail)

def has_voted(pp_str):
    """Checks the SimDemopolis output to see if a vote to trigger the role 
    assignment has taken place
    :rtype: bool"""
    voted_match = re.search(r'ra_vote: ((?:True)|(?:False))', pp_str)
    if voted_match.group(1) == 'True':
        return True
    else:
        return False

def pp2dict(pp_str):
    """Converts the pretty-printed output of SimDemopolis into a Python 
    dictionary. Generally use this in other functions - the functions above 
    are largely helper functions for this.
    
    Parameters
    ----------
    pp_str : string 
        The pretty-printed output of SimDemopolis.
    
    Returns
    -------
    dictionary
        The parsed output, in a python-accessible format.
    """
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

# -----------------------------------------------------------------------------
# Code for analyzing the social networks
# -----------------------------------------------------------------------------

def plot_graph(sn_dict, file_name='', ax=None, title="", show=True,
               circle=False, figure=1, close=False, kamada_kawai=False):
    """Converts a dictionary (JSON) in the nx documentation) in an nx node-link 
    format into an nx graph, then plots this graph using MatPlotLib.
    
    Parameters
    ----------
    sn_dict : dictionary 
        The social network to be plotted, in a NetworkX dictionary
        (JSON) node-link format.    
    file_name : string
        The name of the file to save the graph in. If not 
        specified, the graph is not saved.
    
    ax : matplotlib.pyplot.axes.Axes 
        The set of axes to draw the graph on. If not specified, a new
        figure and axes are created.    
    title : string 
        The title to display on the graph.
    show : bool
        Determines if the graph is displayed after plotting. (default is False)    
    figure : int
        The figure number to plot the graph in. (default is 1)
    close : bool
        Closes the graph after it has been plotted. (default is False)
    circle : bool
        Plots the graph in a circular format. (default is False)
    kamada_kawai : bool
        Plots the graph using the Kamada-Kawai force-directed algorithm. This
        is particularly useful for graphs with hubs, such as scale-free 
        networks. Here, the size of the nodes in the plot scale with their
        degree. (default is False)
    """
    G = nx.json_graph.node_link_graph(sn_dict, False)
    if not ax:
        fig = plt.figure(figure)
        ax = plt.axes()

    if circle:
         nx.draw_circular(G, ax=ax, with_labels=True, node_size=300, font_size=11)
    elif kamada_kawai:
        d = dict(G.degree)
        nx.draw_kamada_kawai(G, ax=ax, with_labels=True,
                 node_size = [v * 100 for v in d.values()])
    else:
         #nx.draw(G, ax=ax, with_labels=True, node_size=600)
         d = dict(G.degree)
         nx.draw(G, ax=ax, with_labels=True,
                 node_size = 300)
    if not nx.is_connected(G):
        print('Graph is not connected')
    if title:
        ax.set_title(title)
    if file_name:
        plt.savefig(file_name)
    if show:
        plt.show()
    if close:
        plt.close(figure)

def gen_socnet(net_top, size=10, prob=0.25, k=2, m=2):
    """Generate social networks from SimDemopolis, without running the role-
    assignment loop
    """
    stdout, stderr = simDemopolis(False, 0, net_top, size, prob, k, m)
    print(stderr)
    sd_dict = pp2dict(stdout)
    nx_dict = sd2nx(sd_dict)
    return nx_dict

def sd2nx(sd_dict):
    """
    Converts a dictionary generated from SimDemopolis to one suitable for
    analysis by networkx.
    """
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

def nx2sd(nx_dict):
    """
    Converts a dictionary generated from a networkx graph to a format suitable
    for SimDemopolis
    """
    agent_list = []
    sn_list = []
    details = {agent['id']:[] for agent in nx_dict['nodes']}
    for link in nx_dict['links']:
        details[link['source']].append(link['target'])
    for agent, sn in details.items():
        agent_list.append(agent)
        sn_list.append(sn)
    return agent_list, sn_list

def gini(x):
    # code from https://stackoverflow.com/questions/39512260/calculating-gini-coefficient-in-python-numpy
    
    # (Warning: This is a concise implementation, but it is O(n**2)
    # in time and memory, where n = len(x).  *Don't* pass in huge
    # samples!)

    # Mean absolute difference
    mad = np.abs(np.subtract.outer(x, x)).mean()
    # Relative mean absolute difference
    rmad = mad/np.mean(x)
    # Gini coefficient
    g = 0.5 * rmad
    return g

def cluster_qs_corr(indep_var, socnet_top, subdir):
    dir_path = os.path.join('Civic-Participation', indep_var, 
                             socnet_top, subdir, 'Rounds')
    clustering = np.loadtxt(open(
                    os.path.join(dir_path, 'clustering.csv'), "rb"), 
                    delimiter=",")
    qs = np.loadtxt(open(
                    os.path.join(dir_path, 'quasi_stability.csv'), "rb"), 
                    delimiter=",")
    qs_clustering = np.vstack((clustering, qs))
    np.savetxt(os.path.join(dir_path, 'qs_clustering.csv'), qs_clustering,  
                    delimiter=",")
    corr = np.corrcoef(clustering, qs)[0,1]
    print('Correlation = {}'.format(corr))
    return corr

def deg_gini_qs_corr(indep_var, socnet_top, subdir):
    dir_path = os.path.join('Civic-Participation', indep_var, 
                             socnet_top, subdir, 'Rounds')
    deg_gini = np.loadtxt(open(
                    os.path.join(dir_path, 'deg_gini.csv'), "rb"), 
                    delimiter=",")
    qs = np.loadtxt(open(
                    os.path.join(dir_path, 'quasi_stability.csv'), "rb"), 
                    delimiter=",")
    deg_gini_qs = np.vstack((deg_gini, qs))
    np.savetxt(os.path.join(dir_path, 'deg_gini_qs.csv'), deg_gini_qs,  
                    delimiter=",")
    corr = np.corrcoef(deg_gini, qs)[0,1]
    print('Correlation = {}'.format(corr))
    return corr
            
# -----------------------------------------------------------------------------
# Code to run the experiments
# -----------------------------------------------------------------------------

class Experiment():
    """
    Base class for SimDemopolis experiments, with functions common to all
    experiments. Subclass this to create new experiments.
    """
    def reset_dir(self):
        """
        Clears the experiment directory contents to allow another experiment
        to be conducted.
        """
        os.makedirs(self.root_dir, exist_ok=True)
        rounds_path =os.path.join(self.root_dir, 'Rounds')
        os.makedirs(rounds_path, exist_ok=True)
        for file_object in os.listdir(rounds_path):
            inner_path = os.path.join(rounds_path, file_object)
            if os.path.isfile(inner_path):
                os.unlink(inner_path)
            else:
                shutil.rmtree(inner_path)

    def load_result(self, file_name=''):
        """
        Loads results for previous experiment from file. Allows results to be
        analyzed without running SimDemopolis again. The loaded results are 
        stored in the Experiment object calling this method.

        Parameters
        ----------
        file_name : str
            File path to load the results from. If not specified, this defaults
            to the experiment root directory.
        """
        if not file_name:
            file_name = os.path.join(self.root_dir, 'full_result.json')
        with open(file_name) as f:
            self.result = json.load(f)
            
    """def load_all_results(self):
        self.experiments = []
        for inner_dir in os.list_dir(self.root_dir):
            if inner_dir.search('expt'):
                result_path = os.path.join(self.root_dir, inner_dir, 'Rounds', 
                                          'full_result.json')
                with open(result_path) as f:
                    result_json = json.load(f)
                    self.experiments.append(result_json)"""
                    
                    
    def run(self, rounds, ticks=10, subdir='Rounds', size=5, prob=0.25, k=2, 
            m=1, load=False):
        """Runs the SimDemopolis program a specified number of times with 
        the set parameters, saves the results, plots the social network graphs,
        and appends the result to the result property of the calling  Experiment
        object The results can be loaded from files if the experiment has been
        run previously.
        
        Parameters
        ----------
        rounds : int
            Number of rounds in the experiment (the number of times 
            SimDemopolis is run).
        ticks : int
            Number of ticks (time units) in each round. (default is 10)
        subdir : string
            Subdirectory of the experiment root to save the results in. 
            (default is 'Rounds')
        size : int
            Size of the SimDemopolis social network. (default is 5)
        prob : float
            Probability that a link is made for a random network, or 
            probability a link is assigned for a small-world network. Does not
            apply to other networks.
        k : int
            Average connectivity of a small_world network. Has no effect on 
            other networks (default is 2)
        m : int
            Number of links per new node for a scale-free network. Has no 
            effect on other networks (default is 1)
        load: bool
            Load previous results from file rather than generate them from
            SimDemopolis. (default is False)
        """
        expt_result = []

        for round_num in range(rounds):
            print('Beginning round {}'.format(round_num))
            
            round_path = os.path.join(self.root_dir, subdir, str(round_num))
            os.makedirs(round_path, exist_ok=True)
            
            if not load: # generate new results
                # Run SimDemopolis
                stdout, stderr = simDemopolis(False, ticks, self.socnet_top, size, 
                                              prob, k, m)
                # Check SimDemopolis returned output
                assert(stdout is not None), "SimDemopolis returned no output" 
                
                with open(os.path.join(round_path, 'raw_output.txt'), 'w') as f:
                    f.write(stdout)
                    
                # Carry on experiment if SimDemopolis fails - continue to next
                # round
                if stderr.find('ERROR:') != -1:
                    print('Error in round {}: see log for details'.format(round_num))
                    with open(os.path.join(round_path, 'error_log.txt'), 'w') as f:
                        f.write(stderr)
                    continue
            else: # load result from file
                with open(os.path.join(round_path, 'raw_output.txt')) as f:
                    stdout = f.read()
                if 'error_log.txt' in os.listdir(round_path):
                    print('Error in round {}: see log for details'.format(round_num))
                    continue
                
            print('Round {} complete'.format(round_num))

            # Convert the SimDemopolis output to a dictionary
            round_dict = pp2dict(stdout)
            with open(os.path.join(round_path, 'result.json'), 'w') as f:
                json.dump(round_dict, f)
            # Convert the SimDemopolis dictionary to an Nx dictionary
            nx_dict = sd2nx(round_dict)
            plot_graph(nx_dict, os.path.join(round_path, 'graph.eps'),
                       show=False, figure=(round_num+2))

            expt_result.append(round_dict)

        with open(os.path.join(self.root_dir, subdir, 'full_result.json'), 'w') as f:
            json.dump(expt_result, f)
        self.result =  expt_result
        
    def plot(self):
        """
        Skleleton function to plot experiment output. Subclass this to add
        the functionality.
        """
        pass
        
    def plot_range(self, rounds=10, ticks=1, load=False):
        """Run and plot a range of experiments in subplots on the same figure,
        modifying an independent variable determined by the indep_var property
        of the calling Experiment object. The graph is saved in the 'Rounds'
        subdirectory of the experiment root.
        
        Parameters
        ----------
        rounds : int
            Number of rounds per experiment. (default is 10)
        ticks : int
            Number of ticks (time units) per round. (default is 1)
        load : bool
            Load previous experiment results from files, rather than run the 
            experiment again. (default is False)
        """
        print('Beginning Experiment Set\n')
        
        print('Independent variable = {}'.format(self.indep_var))
        print('Socal network topology = {}'.format(self.socnet_top))
        var_list = []
        if self.indep_var == 'size':
            var_list = self.size
        elif self.indep_var == 'probability':
            var_list = self.prob
        elif self.indep_var == 'k':
            var_list = self.k
        elif self.indep_var == 'm':
            var_list = self.m

        # Plot height is proportional to the number of rounds, plus extra for 
        # the titles and labels
        plot_height = (0.1*rounds+0.3)*len(var_list)
        plt.figure(1, figsize=[11.0,plot_height])
        old_root_dir = self.root_dir
        for i,var in enumerate(var_list):
            self.root_dir = os.path.join(self.root_dir, "expt{}".format(i+1))
            print('Beginning experiment {}'.format(i+1))
            print('{} = {}\n'.format(self.indep_var, var))
            
            size = self.size
            prob = self.prob
            k = self.k
            m = self.m

            if self.indep_var == 'size':
                size = self.size[i]
            elif self.indep_var == 'probability':
                prob = self.prob[i]
            elif self.indep_var == 'k':
                k = self.k[i]
            elif self.indep_var == 'm':
                m = self.m[i]

            # Custom title, depending on network topology
            if self.socnet_top == 'random1':
                title = r'Random network, $N={}$, $p={}$'.format(size, prob)
            elif self.socnet_top == 'small_world1':
                title = r'Small World Network, $N={}$, $p={}$, $k={}$'.format(size, prob, k)
            elif self.socnet_top == 'scale_free1' or self.socnet_top == 'scale_free2':
                title = r'Scale Free Network, $N={}$, $m={}$'.format(size, m)
            elif self.socnet_top == 'ring':
                title = r'Ring Network, $N={}$'.format(size)

            self.result = []
            subdir = 'Rounds'
            if load:
                self.load_result(os.path.join(self.root_dir, subdir, 'full_result.json'))
            else:
                self.run(rounds, ticks, subdir, size, prob, k, m, load=False)
            self.root_dir = old_root_dir
            plt.figure(1)
            ax = plt.subplot(len(var_list), 1, i+1)
            try:
                self.plot('', False, ax, title)
            except AssertionError as error:
                print('Could not plot experiment {}'.format(i))
                print(error)

        # save and display the experiment output
        plt.tight_layout()
        plt.savefig(os.path.join(self.root_dir,'result.eps'))
        plt.show() # note: this changes the active figure
        
    def quasi_stability(self, cp_matrix):
        """Calculate the quasi stability of each round of a role-assignment 
        experiment. This is equal to the number of changes in whether a vote
        is taking place, divided by the number of rounds.
        
        Parameters
        ----------
        cp_matrix : numpy.ndarray
            2D NumPy array containing the values of whether a vote has taken 
            place (either 1 or zero) for each tick of each round of the 
            experiment. The rounds are in the 1st dimension, and the ticks are 
            in the 2nd dimension.
            
        Returns
        -------
        qs_vector : numpy.ndarray
            1D NumPy array containing the quasi-stability values for each 
            round. These are floats between 0 and 1.
        """
        num_rounds = cp_matrix.shape[0]
        num_ticks = cp_matrix.shape[1]
        qs_vector = np.zeros(num_rounds)
        for expt_round in range(num_rounds):
            num_changes = 0
            last_val = 0
            for tick in range(num_ticks):
                if cp_matrix[expt_round, tick] != last_val:
                    last_val = cp_matrix[expt_round, tick]
                    num_changes = num_changes + 1
            qs_vector[expt_round] = num_changes/num_ticks
        return qs_vector
    
    def clustering(self):
        """Calculate the local clustering coefficients of the social networks of
        each round of the experiment, from the result property of the caller
        object. A graph is creating for this purpose within the function.
        
        Return
        ------
        c : numpy.ndarray
            1D NumPy array containing the clustering coefficients of each 
            round of the experiment.
        """
        num_rounds = len(self.result)
        c = np.zeros(num_rounds)
        for i,expt_round in enumerate(self.result):
            nx_dict = sd2nx(expt_round)
            G = nx.json_graph.node_link_graph(nx_dict, False, False)
            c[i] = nx.transitivity(G)
        return c
    
    def degree_time_in_role(self):   
        """Calulate the social network degree and time in role of each agent
        in SimDemopolis
        """
        round_total = len(self.result)
        output_list = []

        for round_num in range(round_total):
            degree_dict = {}
            round_dict = self.result[round_num]
            agent_list = round_dict['tick1']['agents']
            agent_num = len(agent_list)
            degree_tir_vec = np.zeros((agent_num, 2))
            for agent in agent_list:
                agent_name = agent['agent']
                agent_degree = len(agent['social_network'])
                degree_dict[agent_name] = agent_degree
            tir_list = round_dict['Institution_End']['timeinrole']
            for i,tir in enumerate(tir_list):
                agent_name, agent_tir = list(tir.items())[0]
                agent_degree = degree_dict[agent_name]
                degree_tir_vec[i, 0] = agent_degree
                degree_tir_vec[i, 1] = agent_tir
            output_list.append(degree_tir_vec)
        return output_list
    
    def deg_gini(self):
        tir_list = self.degree_time_in_role()
        deg_gini = np.zeros(len(tir_list))
        for i in range(len(tir_list)):
            deg_gini[i] = gini(tir_list[i][:,1])
        return deg_gini
        
    def __init__(self, socnet_top, root_dir, dir_reset=True, size=5, prob=0.25,
                 indep_var='', k=2, m=2):
        """Object properties are initialized
        
        Parameters
        ----------
        socnet_top : string
            Social network topology being investigated in the experiment. This
            must be one of 'ring', 'scale_free1', 'random1' or 'small_world1'.
            The 1 at the end of the names is because there are 2 versions of
            the social network gernerating algorithms in SimDemopolis. The 
            versions used here ensure that all nodes have at least one link. 
            Whilst this makes the networks mathmatically imperfect, it prevents
            a divide-by-zero error in SimDemopolis.
        root_dir : string
            Root directory to store the experiment results in.
        dir_reset : bool
            If enabled, the self.reset_dir() method is run, clearing the root
            directory of previous results. (default is False)
        size : int
            Size of the social network (number of nodes). (default is 5). If 
            size is the independent variable, this should be a list of ints.
        prob : float
            Probability of link formation for a random network, or probability
            of link reassignment for a small-world network. If probability is
            the independent variable, this should be a list of floats.       
        k : int
            Average degree for a small-world network. If k is the independent
            variable, this should be a list of ints.
        m : int
            Number of links added per new node for a scale-free network. If m
            is the independent variable, this should be a list of ints.
        indep_var : string
            Independent variable in the experiment. Must be one of 'size', 
            'probability', 'k', 'm'.
        """
        self.result = []
        self.root_dir = root_dir
        if dir_reset:
            self.reset_dir()
        self.prob = prob
        self.size = size
        self.indep_var = indep_var
        self.socnet_top = socnet_top
        self.k = k
        self.m = m

class Skiver(Experiment):
    def plot(self, filename, show=True, ax=None, title=""):
        save_fig = False # Save figure if set of axes not provided
        if not ax:
            fig, ax = plt.subplots()
            save_fig = True
        
        time_in_role = self.get_time_in_role()
        ax.boxplot(time_in_role, vert=False)
        ax.set_ylabel('Round Number')
        ax.set_xlabel('Time in Role')
        if show:
            plt.show()
        if save_fig and filename:
            plt.savefig(filename)
        
    def get_time_in_role(self):
        expt_result = self.result
        output = []
        for res in expt_result:
            tir_dicts = res['Institution_End']['timeinrole']
            # Each time-in-role item is of the form {'agent': 'val'}
            tir_list = [int(agent_tir.popitem()[1]) for agent_tir in tir_dicts]
            output.append(tir_list)
        return output

    def __init__(self, socnet_top='random', root_dir='Skiver',
                 dir_reset=True, size=5, prob=0.25,
                 indep_var='', k=2, m=1):
        """Object properties are initialized, by creating an object of the 
        subclass (Experiment)
        
        Parameters
        ----------
        socnet_top : string
            Social network topology being investigated in the experiment. This
            must be one of 'ring', 'scale_free1', 'random1' or 'small_world1'.
            The 1 at the end of the names is because there are 2 versions of
            the social network gernerating algorithms in SimDemopolis. The 
            versions used here ensure that all nodes have at least one link. 
            Whilst this makes the networks mathmatically imperfect, it prevents
            a divide-by-zero error in SimDemopolis.
        root_dir : string
            Root directory to store the experiment results in.
        dir_reset : bool
            If enabled, the self.reset_dir() method is run, clearing the root
            directory of previous results. (default is False)
        size : int
            Size of the social network (number of nodes). (default is 5). If 
            size is the independent variable, this should be a list of ints.
        prob : float
            Probability of link formation for a random network, or probability
            of link reassignment for a small-world network. If probability is
            the independent variable, this should be a list of floats.       
        k : int
            Average degree for a small-world network. If k is the independent
            variable, this should be a list of ints.
        m : int
            Number of links added per new node for a scale-free network. If m
            is the independent variable, this should be a list of ints.
        indep_var : string
            Independent variable in the experiment. Must be one of 'size', 
            'probability', 'k', 'm'.
        """
        super().__init__(socnet_top, root_dir, dir_reset, size, prob,
             indep_var, k, m)

class CivicParticipation(Experiment):
    def eval_cp(self):
        """Examines the results of the civic participation simulation after it 
        has been run, and construct a matrix containing the binary state of
        whether voting to decide whether to run the role-assignment protocol
        has taken place.
        
        Returns
        -------
        cp_matrix : numpy.ndarray
            2D numpy array containing the role-assignment voting state. Can 
            either be 1 or 0. Experiment rounds are in dimension 1, and ticks
            are in dimension 2.
        """ 
        round_total = len(self.result)
        tick_total = len(self.result[0])-2
        assert (tick_total >= 1), " Cannot plot civic participation graph - no data available."
        cp_mtrx = np.zeros((round_total, tick_total))
        
        for round_num in range(round_total):
            round_dict = self.result[round_num]
            for tick_num in range(tick_total):
                tick_key = "tick{}".format(tick_num + 1)
                vote_successful = round_dict[tick_key]['ra_vote']
                if vote_successful == 'True':
                    cp_mtrx[round_num, tick_num] = 1.0
        return cp_mtrx
    
    def plot(self, filename='', show=True, ax=None, title=""):
        """
        Plots a colormap plot of the state of role-assignment voting, for each
        tick of each experiment round.
        
        Parameters
        ----------
        filename : string
            Name of the file to save the plot in. This only happens when 
            ax is not specified. (default is '')
        show : bool
            Displays the figure after plotting is finished. (default is false)
        ax : matplotlib.pyplot.axes.Axes 
            The set of axes to draw the colormap on. If not specified, a new
            figure and axes are created.
        title : string
            Title to give the graph.
        """
        save_fig = False # Save figure if set of axes not provided
        if not ax:
            fig, ax = plt.subplots()
            save_fig = True
        
        im_matrix = self.eval_cp()
        round_total, tick_total = im_matrix.shape
        
        c = ax.pcolormesh(im_matrix)
        print('Civic Participation matrix output')
        print(im_matrix)
        if not title:
            title = 'Role Rassignment'
        ax.set_title(title)
        ax.set_ylabel('round')
        ax.set_xlabel('tick')
        ax.set_xticks(np.arange(2,tick_total,2))
        ax.set_yticks(np.arange(2,round_total+1,2))
        if show:
            plt.show()
        if save_fig and filename:
            plt.savefig(filename)

    
    def __init__(self, socnet_top='random', root_dir='Civic-Participation',
                 dir_reset=True, size=5, prob=0.25,
                 indep_var='', k=2, m=1):
        """Object properties are initialized, by creating an object of the 
        subclass (Experiment)
        
        Parameters
        ----------
        socnet_top : string
            Social network topology being investigated in the experiment. This
            must be one of 'ring', 'scale_free1', 'random1' or 'small_world1'.
            The 1 at the end of the names is because there are 2 versions of
            the social network gernerating algorithms in SimDemopolis. The 
            versions used here ensure that all nodes have at least one link. 
            Whilst this makes the networks mathmatically imperfect, it prevents
            a divide-by-zero error in SimDemopolis.
        root_dir : string
            Root directory to store the experiment results in.
        dir_reset : bool
            If enabled, the self.reset_dir() method is run, clearing the root
            directory of previous results. (default is False)
        size : int
            Size of the social network (number of nodes). (default is 5). If 
            size is the independent variable, this should be a list of ints.
        prob : float
            Probability of link formation for a random network, or probability
            of link reassignment for a small-world network. If probability is
            the independent variable, this should be a list of floats.       
        k : int
            Average degree for a small-world network. If k is the independent
            variable, this should be a list of ints.
        m : int
            Number of links added per new node for a scale-free network. If m
            is the independent variable, this should be a list of ints.
        indep_var : string
            Independent variable in the experiment. Must be one of 'size', 
            'probability', 'k', 'm'.
        """
        super().__init__(socnet_top, root_dir, dir_reset, size, prob,
             indep_var, k, m)
        


# -----------------------------------------------------------------------------
# Code to run the SimDemopolis Prolog program
# -----------------------------------------------------------------------------

def simDemopolis(interactive, ticks, socnet_top='scale_free2', size=5,
                 prob=0.25, k=2, m=1, stack_limit='100g', table_space='50g'):
    """
    Run the SimDemopolis Prolog Queries, and return the stdout and stderr text
    
    Parameters
    ----------
    interactive : bool
        For debugging use only. If True, Prolog will run in interactive mode,
        which means that it's text will print to Python's output as it arrives,
        not after SimDemopolis is run. This enables the Prolog debugger to be
        run. After the run query of SimDemopolis is finished, Prolog enters
        interactive mode, so arbitrary queries can be entered by the user.
        (Note: this mode doesn't work in IPython).
    ticks : int
        Number of ticks (time units) in each round.
    socnet_top : string
        Social network topology being investigated in the experiment. This
        must be one of 'ring', 'scale_free1', 'random1' or 'small_world1'.
        The 1 at the end of the names is because there are 2 versions of
        the social network gernerating algorithms in SimDemopolis. The 
        versions used here ensure that all nodes have at least one link. 
        Whilst this makes the networks mathmatically imperfect, it prevents
        a divide-by-zero error in SimDemopolis.
    size : int
        Size of the SimDemopolis social network. (default is 5)
    prob : float
        Probability that a link is made for a random network, or 
        probability a link is assigned for a small-world network. Does not
        apply to other networks. (default is 0.25)
    k : int
        Average connectivity of a small_world network. Has no effect on 
        other networks (default is 2)
    m : int
        Number of links per new node for a scale-free network. Has no 
        effect on other networks (default is 1)
    stack_limit : string
        Amount of memory allocated to the Prolog stack. (Provided as a 
        command-line argument to Prolog) See the SWI-Prolog documentation for 
        more details. (default is '100g')        
    table_space : string
        Amount of memory allocated to the Prolog table space. (Provided as a 
        command-line argument to Prolog) See the SWI-Prolog documentation for
        more details.        
    """
    halt = ""
    if not interactive:
        halt = "-t halt "
        
    # Command-line script which runs constructs SimDemopolis in SWI-Prolog, 
    # then runs the main query, run afterwards.
    sim_script = "swipl --stack_limit={} --table_space={} -s main.pl -g run {} \
    --socnet {} --agent_num {} --probability {} --small_world_connections {} \
    --scale_free_links {} --ticks {}".format(stack_limit, table_space, halt, 
    socnet_top, size, prob, k, m, ticks)
    Output = subprocess.run(shlex.split(sim_script),
                            text=True,
                            shell=True,
                            capture_output=(not interactive))
    return (Output.stdout, Output.stderr)

# -----------------------------------------------------------------------------
# Plot the graphs shown in the report
# -----------------------------------------------------------------------------

def plot_sn_growth(net_top, size, prob=0.25, k=2):
    nx_dict = gen_socnet(net_top, size, prob, k)
    
def plot_qs_clustering(socnet_top='random1', subdir='expt1'):
    """Plots a graph of quasi-stability against the local clustering 
    coefficient, based on a previously-run experiment. Quasi stability is 
    defined as the number of times the voting state changes divided by the 
    number of experiment rounds."""
    expt_dir = os.path.join('Civic-Participation', 'm', socnet_top, subdir,
                            'Rounds')
    cp = CivicParticipation(socnet_top, expt_dir, False)
    cp.load_result()
    cp_matrix = cp.eval_cp()
    qs_vec = cp.quasi_stability(cp_matrix)
    qs_mean = np.mean(qs_vec)
    print('Mean Quasi-Stability = {}'.format(qs_mean))
    
    c_vec = cp.clustering()
    c_mean = np.mean(c_vec)
    print('Mean Clustering Coefficient = {}'.format(c_mean))
    # Save the quasi stability and clustering data as csv files
    np.savetxt(os.path.join(expt_dir,"quasi_stability.csv"),
                  qs_vec, delimiter=",")
    np.savetxt(os.path.join(expt_dir,"clustering.csv"),
                  c_vec, delimiter=",")
    
    plt.plot(c_vec, qs_vec, 'rx')
    plt.xlabel('Local Clustering Coefficient')
    plt.ylabel('Quasi-Stability (changes per tick)')
    plt.savefig(os.path.join(expt_dir,'qs_clustering.eps'))
    plt.show()
    
def plot_degree_tir(socnet_top='scale_free1', subdir='expt3', round_num=13):
    expt_dir = os.path.join('Civic-Participation', 'm', socnet_top, subdir,
                            'Rounds')
    cp = CivicParticipation(socnet_top, expt_dir, False)
    cp.load_result()
    deg_tir_list = cp.degree_time_in_role()
    deg_tir_matrix = deg_tir_list[round_num]
    data_path = os.path.join(expt_dir, 
                             'degree_time_in_role{}.csv'.format(round_num))
    np.savetxt(data_path, deg_tir_matrix, delimiter=",")
    plt.plot(deg_tir_matrix[:,0], deg_tir_matrix[:,1], 'rx')
    plt.title('{}, round {}'.format(socnet_top, round_num+1))
    plt.xlabel('Node Degree')
    plt.ylabel('Time In Role')
    img_path = os.path.join(expt_dir, 
                             'degree_time_in_role{}.eps'.format(round_num))
    plt.savefig(img_path)
    plt.show()
    
def plot_deggini_tir(socnet_top='scale_free1', subdir='expt1'):
    expt_dir = os.path.join('Civic-Participation', 'm', socnet_top, subdir,
                            'Rounds')
    cp = CivicParticipation(socnet_top, expt_dir, False)
    cp.load_result()
    cp_matrix = cp.eval_cp()
    qs_vec = cp.quasi_stability(cp_matrix)
    deg_gini = cp.deg_gini()
    # Save the Degree gini data as a csv file
    np.savetxt(os.path.join(expt_dir,"deg_gini.csv"),
                  deg_gini, delimiter=",")
    plt.plot(deg_gini, qs_vec, 'rx')
    plt.xlabel('SN Degree Gini Coefficient')
    plt.ylabel('Quasi-Stability (changes per tick)')
    plt.savefig(os.path.join(expt_dir,'deg_gini_tir.eps'))
    plt.show()
    

def plot_ring(size=10):
    """Generates a ring network of the specified size using
    SimDemopolis, and plots it."""
    plt.figure(1, figsize=[4.0,3.0])
    nx_dict = gen_socnet('ring', size)
    plot_graph(nx_dict, os.path.join('Network-Plots','ring.eps'), circle=True)

def plot_k_ring(size=10):
    """Generates a k-ring network of the specified size using
    SimDemopolis, and plots it."""
    plt.figure(1, figsize=[6.0,4.0])
    nx_dict = gen_socnet('small_world', size, prob=0.0, k=2)
    plot_graph(nx_dict, os.path.join('Network-Plots','k_ring.eps'), circle=True)

def plot_small_world(size=10):
    """Generates a small-world network of the specified size using
    SimDemopolis, and plots it."""
    plt.figure(1, figsize=[11.0,4.0])
    betas = [0.0, 0.25, 0.5, 1.0]
    for i,beta in enumerate(betas):
        ax = plt.subplot(1, len(betas), i+1)
        nx_dict = gen_socnet('small_world', size, prob=beta, k=2)
        plot_graph(nx_dict,
                   os.path.join('Network-Plots','small_world.eps'),
                   ax=ax, circle=True, show=False,
                   title=r'$\beta={}$'.format(beta))
    plt.show()

def plot_random(size=10):
    """Generates a random network of the specified size using
    SimDemopolis, and plots it."""
    plt.figure(1, figsize=[11.0,4.0])
    p_list = [0.25, 0.5, 1.0]
    for i,p in enumerate(p_list):
        ax = plt.subplot(1, len(p_list), i+1)
        nx_dict = gen_socnet('random', size, prob=p, k=2)
        plot_graph(nx_dict,
                   os.path.join('Network-Plots','random.eps'),
                   ax=ax, circle=True, show=False,
                   title=r'$p={}$'.format(p))
    plt.show()

def plot_scale_free(size=20):
    """Generates a scale-free network of the specified size using
    SimDemopolis, and plots it."""
    plt.figure(1, figsize=[20.0,10.0])
    ax = plt.gca()
    nx_dict = gen_socnet('scale_free2', size)
    plot_graph(nx_dict, os.path.join('Network-Plots','scale_free3.eps'), ax=ax,
               kamada_kawai=True)

def plot_scale_free_growth():
    """Generates and plots a scale-free networks of a range of sizes using 
    SimDemopolis, to illustrate the growth of these networks.
    """
    size_list = range(1,9)
    plt.figure(1, figsize=[20.0,10.0])
    for i,size in enumerate(size_list):
        ax = plt.subplot(2, len(size_list)/2, i+1)
        nx_dict = gen_socnet('scale_free', size)
        plot_graph(nx_dict,
                   os.path.join('Network-Plots','scale_free_growth.eps'),
                   ax=ax, show=False, title=r'$N={}$'.format(size), 
                   kamada_kawai=True)                  
    plt.show()

# -----------------------------------------------------------------------------
# Run and plot experiment results shown in the report
# -----------------------------------------------------------------------------

# Civic participation experiment, with size as the independent variable
def cp_size(socnet_top, size_list):
    root_dir = os.path.join('Civic-Participation','size',socnet_top)
    try:
        cp = CivicParticipation(socnet_top, dir_reset=True, size=size_list,
                                prob=0.25, indep_var='size', root_dir=root_dir)
        cp.plot_range(rounds=20, ticks=40, load=False)
    except AssertionError as error:
        print('Civic participation size experiment failed')
        print(error)

def cp_prob(socnet_top, prob_list):
    root_dir = os.path.join('Civic-Participation',
                            'probability', socnet_top)
    try:
        cp = CivicParticipation(socnet_top, dir_reset=True, size=30,
                                prob=prob_list, indep_var='probability', 
                                root_dir=root_dir)
        cp.plot_range(rounds=20, ticks=40, load=False)
    except AssertionError as error:
        print('Civic participation probability experiment failed')
        print(error)
        
def sk_prob(socnet_top, prob_list):
    root_dir = os.path.join('Skiver',
                            'probability', socnet_top)
    try:
        sk = Skiver(socnet_top, dir_reset=True, size=30,
                                prob=prob_list, indep_var='probability', 
                                root_dir=root_dir)
        sk.plot_range(rounds=10, ticks=40, load=False)
    except AssertionError as error:
        print('Skiver probability experiment failed')
        print(error)

def cp_k(k_list):
    # the k parameter only applies to small-world networks
    socnet_top = 'small_world1' 
    root_dir = os.path.join('Civic-Participation', 'k', socnet_top)
                            
    try:
        cp = CivicParticipation(socnet_top, dir_reset=True, size=30, prob=0.25,
                                indep_var='k', k=k_list, root_dir=root_dir)                                
        cp.plot_range(rounds=20, ticks=40, load=False)
    except AssertionError as error:
        print('Civic participation small-world k experiment failed')
        print(error)
        
def sk_k(k_list):
    # the k parameter only applies to small-world networks
    socnet_top = 'small_world1' 
    root_dir = os.path.join('Skiver', 'k', socnet_top)
                            
    try:
        sk = Skiver(socnet_top, dir_reset=True, size=30, prob=0.25,
                                indep_var='k', k=k_list, root_dir=root_dir)                                
        sk.plot_range(rounds=10, ticks=40, load=False)
    except AssertionError as error:
        print('Skiver small-world k experiment failed')
        print(error)
        
def cp_m(m_list):
    # the m parameter only applies to scale-free networks
    socnet_top = 'scale_free2' 
    root_dir = os.path.join('Civic-Participation', 'm', socnet_top)
    
    try:
        cp = CivicParticipation(socnet_top, dir_reset=True, size=30,
                                indep_var='m', m=m_list, root_dir=root_dir)                                
        cp.plot_range(rounds=20, ticks=40, load=False)
    except AssertionError as error:
        print('Civic participation scale-free m experiment failed')
        print(error)
        
        
def sk_m(m_list):
    # the m parameter only applies to scale-free networks
    socnet_top = 'scale_free1' 
    root_dir = os.path.join('Skiver', 'm', socnet_top)
    
    try:
        sk = Skiver(socnet_top, dir_reset=True, size=30,
                                indep_var='m', m=m_list, root_dir=root_dir)                                
        sk.plot_range(rounds=10, ticks=40, load=False)
    except AssertionError as error:
        print('Skiver scale-free m experiment failed')
        print(error)
        
# -----------------------------------------------------------------------------
# Test code (for development)
# -----------------------------------------------------------------------------
def test_parse():
    """
    Test the text parsing functionality from a samle SimDemopolis output from 
    a file
    """
    with open('Development/test_output.txt') as f:
        test_str = f.read()
        test_dict = pp2dict(test_str)
    with open('Development/test_json.json', 'w') as f:
        json.dump(test_dict, f)
    return test_dict

def create_test_output():
    """
    Write sample SimDemopolis output to file (for debugging)
    """
    (stdout, stderr) = simDemopolis(False, 0)
    with open('Development/test_output.txt', 'w') as f:
        f.write(stdout)
    print(stderr)

def test_cp_graph():
    cp = CivicParticipation()
    cp.load_result()
    sd_dict = cp.result[0]
    nx_dict = sd2nx(sd_dict)
    agent_list, sn_list = nx2sd(nx_dict)
    
def test_skiver_graph():
    sk = Skiver()
    sk.load_result()
    sd_dict = sk.result[0]
    nx_dict = sd2nx(sd_dict)
    agent_list, sn_list = nx2sd(nx_dict)
    
def test_cp_size_plot_range():
    socnet_top='scale_free1'
    root_dir = os.path.join('Civic-Participation','Test-Size',socnet_top)
    size_list = [7,10,10]
    cp = CivicParticipation(socnet_top, dir_reset=True, size=size_list,
                            prob=0.25, indep_var='size', root_dir=root_dir)
    cp.plot_range(rounds=10, ticks=5)
    
def test_sk_size_plot_range():
    socnet_top='scale_free1'
    root_dir = os.path.join('Skiver','Test-Size',socnet_top)
    size_list = [7,10,10]
    sk = Skiver(socnet_top, dir_reset=True, size=size_list,
                            prob=0.25, indep_var='size', root_dir=root_dir)
    sk.plot_range(rounds=10, ticks=5)
    
def test_prob_plot_range():
    socnet_top='small_world1'
    root_dir = os.path.join('Civic-Participation','Test-Prob',socnet_top)
    prob_list = [0.25, 0.5, 0.75]
    cp = CivicParticipation(socnet_top, dir_reset=True, size=7,
                            prob=prob_list, indep_var='probability', root_dir=root_dir)
    cp.plot_range(rounds=10, ticks=3)
    
def test_k_plot_range():
    socnet_top='small_world1'
    root_dir = os.path.join('Civic-Participation','Test-k',socnet_top)
    k_list = [1,2, 3, 4]
    cp = CivicParticipation(socnet_top, dir_reset=True, size=7, prob=0.25, 
                            k=k_list, indep_var='k', root_dir=root_dir)
    cp.plot_range(rounds=10, ticks=3)

def test_cp_m_plot_range():
    socnet_top='scale_free1'
    root_dir = os.path.join('Civic-Participation','Test-m',socnet_top)
    m_list = [1, 2]
    cp = CivicParticipation(socnet_top, dir_reset=True, size=7, m=m_list, 
                            indep_var='m', root_dir=root_dir)                        
    cp.plot_range(rounds=10, ticks=3)
    
    
def test_sk_m_plot_range():
    socnet_top='scale_free1'
    root_dir = os.path.join('Skiver','Test-m',socnet_top)
    m_list = [1, 2]
    cp = CivicParticipation(socnet_top, dir_reset=True, size=7, m=m_list, 
                            indep_var='m', root_dir=root_dir)                        
    cp.plot_range(rounds=10, ticks=3)

if __name__ == "__main__":
    # cp_size('small_world1', [20,30,40])
    #cp_prob('random1',[0.25, 0.5, 0.75, 1.0])
    sk_m([1,2,3,5])
    sk_prob('random1', [0.25,0.5,0.75])
    #test_sk_m_plot_range()
    #create_test_output()