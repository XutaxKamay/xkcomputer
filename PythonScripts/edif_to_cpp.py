import sys
import spydrnet as sdn

netlist = sdn.parse(sys.argv[1])

for instance in netlist.get_instances():
    print("Instance:",instance.name," Reference definition:",instance.reference.name)
    print('\t',"Instance's pins' types")
    for pin in instance.pins:
        print('\t\t',pin.__class__)
    print('\t',"Definition's pins' types")
    for pin in instance.reference.get_pins():
        print('\t\t',pin.__class__)
