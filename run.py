'''
Automatically run SimDemopolis, analyse and plot the data.
'''

import os

"""
    Runs the SimDemopolis Prolog experiment suite, and returns the results
"""
def simDemopolis(interactive):
    halt = ""
    if interactive:
        halt = "-t halt "
    sim_script = "swipl -s main.pl -g run {}--socnet small_world --ticks 2".format(halt)
    return os.popen(sim_script).read()

if __name__ == "__main__":
    print(simDemopolis(True))
