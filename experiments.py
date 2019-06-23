# -----------------------------------------------------------------------------
# Code to run the experiments
# -----------------------------------------------------------------------------

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
    
    def run(self, rounds, socnet_top, ticks=10, 
            size=5, prob=0.25, k=2):
        expt_result = []
    
        for round_num in range(rounds):
            # Select the independent variable of the experiment
            if self.indep_var == 'size':
                size = self.size_list[round_num]
            elif self.indep_var == 'probability':
                prob = self.prob_list[round_num]
                
            # Run SimDemopolis
            stdout, stderr = simDemopolis(True, ticks, 
                                          socnet_top, size, prob, k)
            
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
            
            # Convert the SimDemopolis output to a dictionary
            round_dict = pp2dict(stdout)
            with open(os.path.join(round_path, 'result.json'), 'w') as f:
                json.dump(round_dict, f)
            # Convert the SimDemopolis dictionary to an Nx dictionary
            nx_dict = sd2nx(round_dict)
            plot_graph(nx_dict, os.path.join(round_path, 'graph.eps'))
                
            expt_result.append(round_dict)
            
        with open(os.path.join(self.root_dir, 'full_result.json'), 'w') as f:
            json.dump(expt_result, f)
        self.result =  expt_result
        
    def __init__(self, root_dir, dir_reset=True, size=5, indep_var='', 
                 prob_list=[], size_list=[]):
        self.result = []
        self.root_dir = root_dir
        if dir_reset:
            self.reset_dir()
        self.indep_var = indep_var
        self.prob_list = prob_list
        self.size_list = size_list

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
        plt.title('Role Rassignment')
        plt.ylabel('round')
        plt.xlabel('tick')
        if show:
            plt.show()
        plt.savefig(filename)
        
    def plot_range(self):
            
   
    def __init__(self, root_dir='Civic-Participation', dir_reset=True):
        super().__init__(root_dir, dir_reset)
