import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.cbook as cbook
import csv
import numpy as np
import collections
from os import listdir 
from os.path import isfile  , join 


releases = [  "memcached-1.4.22" , "memcached-1.4.30",  "memcached-1.5.12" , "memcached-1.5.20" , "memcached-1.6.9" ]
categories = [ "LoadAfter" ,"StoreAfter", "NopAfter","LoadAndStoreAfter","WithBranch","before"]
values = ["before","2", "4", "8"]


def readCSV(file_path,sfile,d):
  with open(file_path, newline='') as file:
    content = csv.reader(file, delimiter=',')
    title = ''
    weight = 0.0
    instructions = 0.0
    if(sfile == 'summaryInstPerBBHistogram.csv'):
        title = 'InstructionsperBasicBlock'
    elif(sfile == 'summaryInstructionsPerFunctionHistogram.csv'):
        title = 'InstructionsPerFunction'
    elif(sfile == 'summaryLoadPerBBHistogram.csv'):
        title = 'LoadInstructionsperBasicBlock'
    elif(sfile == 'summaryLoadPerFunctionHistogram.csv'):
        title = 'LoadInstructionsPerFunction'
    elif(sfile == 'summaryStatBasicBlocksHistogram.csv'):
        title = 'BasicBlocksPerFunction'
    elif(sfile == 'summaryStatFunctionHistogram.csv'):
        title = 'NumberOfFunctions'
    elif(sfile == 'summaryStorePerBBHistogram.csv'):
        title = 'StoreInstructionsperBasicBlock'
    elif(sfile == 'summaryStorePerFunctionHistogram.csv'):
        title = 'StoreInstructionsPerFunction'
    elif(sfile == 'summaryOtherInstsPerFunctionHistogram.csv'):
        title = 'otherInstructionsPerFunction'
    elif(sfile == 'summaryOtherPerBBHistogram.csv'):
        title = 'otherInstructionsPerBasicBlock'
    for row in content:
        if(row[0] == 'Func' ):
           d[title] =  int(row[1])
        elif(row[0] == 'perc' or row[0] == 'avg'):
            d[title] = float(instructions/weight)
            break
        else:
            instructions += (float(row[0]) * float(row[1]))
            weight += float(row[1])
    	# elif int(row[0]) in d:
    	# 	d[int(row[0])] = d[int(row[0])] + int(row[1])
    	# else:
    	# 	d[int(row[0])] = int(row[1])

prop_cycle = plt.rcParams['axes.prop_cycle']
colors = prop_cycle.by_key()['color']

def plotMultipleHistFromData(data_array, labels = None,
	ylabel = None, logScaleX = False, logScaleY = False, legend = False,
	output_file = 'fig.pdf', plotAverage = False, averageLineStyle = []):
	fig = plt.figure(figsize=(10, 6), dpi=1000)
	# plt.subplot(2, 1, 1)
	for i, data in enumerate(data_array):
		od = collections.OrderedDict(sorted(data.items()))
		plt.plot(od.keys(), od.values(), label=labels[i] if labels is not None else str(i))
		if plotAverage:
			avg = 0
			s = 0
			for k in od.keys():
				s = s + k * od[k]
			#only for dynamic stats, for static this should be uncommented
			avg = s / len(od.keys())
			plt.axhline(y=avg, color=colors[i], linestyle=averageLineStyle[i % len(averageLineStyle)] if len(averageLineStyle) != 0 else '--')
	if logScaleX:
		plt.xscale('log')
	if logScaleY:
		plt.yscale('log')
	if ylabel:
		plt.ylabel(ylabel)
	if legend:
		plt.legend(loc='upper right')
	plt.savefig(output_file)
	plt.close()


for category in categories:      ## list of passes
    for release in releases:
        releaseDirectory = "../memcached_output/output/"+category+"/"+release+"/"
        NumberOfFunctions = []          ## list of releases for passes
        BasicBlocksPerFunction = []
        InstructionsperBasicBlock = []
        LoadInstructionsperBasicBlock = []
        StoreInstructionsperBasicBlock =[]
        otherInstructionsPerBasicBlock =[]
        InstructionsPerFunction=[]
        LoadInstructionsPerFunction =[]
        StoreInstructionsPerFunction =[]
        otherInstructionsPerFunction =[]
        
        for value in values:  ## list of values
            total = dict()    ## holds all data of a specific realease and and value
            filesDirectory = "../memcached_output/output/"+category+"/"+release+"/"+value+"/"
            if(value == "before"):
                filesDirectory = "../memcached_output/output/"+value+"/"+release+"/"
                print(filesDirectory)
            
            if(category == "WithBranch" and value != "before"):
                if( value =="2"):
                     filesDirectory = "../memcached_output/output/WithBranch"+"/"+release+"/"
                else:
                    continue
            elif(category =="before"):
                filesDirectory = "../memcached_output/output/before"+"/"+release+"/"
            
            files = [  f for f in listdir(filesDirectory ) if isfile(join( filesDirectory , f)) ]
            for sfile in files:
                 readCSV(filesDirectory+sfile,sfile,total)
            for key, val in total.items():
                if key =='NumberOfFunctions':
                    NumberOfFunctions.append(val)
                elif key == 'BasicBlocksPerFunction':
                    BasicBlocksPerFunction.append(val)
                elif key == 'InstructionsperBasicBlock':
                    InstructionsperBasicBlock.append(val)
                elif key == 'LoadInstructionsperBasicBlock':
                    LoadInstructionsperBasicBlock.append(val)
                elif key == 'StoreInstructionsperBasicBlock':
                    StoreInstructionsperBasicBlock.append(val)
                elif key == 'otherInstructionsPerBasicBlock':
                    otherInstructionsPerBasicBlock.append(val)
                elif key == 'InstructionsPerFunction':
                    InstructionsPerFunction.append(val)
                elif key == 'LoadInstructionsPerFunction':
                    LoadInstructionsPerFunction.append(val)
                elif key == 'StoreInstructionsPerFunction':
                    StoreInstructionsPerFunction.append(val)
                elif key == 'otherInstructionsPerFunction':
                    otherInstructionsPerFunction.append(val)
        with open(releaseDirectory+"NumberOfFunctions.csv", "w") as f:
            writer = csv.writer(f)
            writer.writerows([NumberOfFunctions])
        with open(releaseDirectory+"BasicBlocksPerFunction.csv", "w") as f:
            writer = csv.writer(f)
            writer.writerows([BasicBlocksPerFunction])
        with open(releaseDirectory+"InstructionsperBasicBlock.csv", "w") as f:
            writer = csv.writer(f)
            writer.writerows([InstructionsperBasicBlock])
        with open(releaseDirectory+"LoadInstructionsperBasicBlock.csv", "w") as f:
            writer = csv.writer(f)
            writer.writerows([LoadInstructionsperBasicBlock])
        with open(releaseDirectory+"StoreInstructionsperBasicBlock.csv", "w") as f:
            writer = csv.writer(f)
            writer.writerows([StoreInstructionsperBasicBlock])
        with open(releaseDirectory+"otherInstructionsPerBasicBlock.csv", "w") as f:
            writer = csv.writer(f)
            writer.writerows([otherInstructionsPerBasicBlock])
        with open(releaseDirectory+"InstructionsPerFunction.csv", "w") as f:
            writer = csv.writer(f)
            writer.writerows([InstructionsPerFunction])
        with open(releaseDirectory+"LoadInstructionsPerFunction.csv", "w") as f:
            writer = csv.writer(f)
            writer.writerows([LoadInstructionsPerFunction])
        with open(releaseDirectory+"StoreInstructionsPerFunction.csv", "w") as f:
            writer = csv.writer(f)
            writer.writerows([StoreInstructionsPerFunction])
        with open(releaseDirectory+"otherInstructionsPerFunction.csv", "w") as f:
            writer = csv.writer(f)
            writer.writerows([otherInstructionsPerFunction])
        
    releaseDirectory = "../memcached_output/output/"+category+"/"
    NumberOfFunctions = []          ## list of releases for passes
    BasicBlocksPerFunction = []
    InstructionsperBasicBlock = []
    LoadInstructionsperBasicBlock = []
    StoreInstructionsperBasicBlock =[]
    otherInstructionsPerBasicBlock =[]
    InstructionsPerFunction=[]
    LoadInstructionsPerFunction =[]
    StoreInstructionsPerFunction =[]
    otherInstructionsPerFunction =[]
    for release in releases:
        with open(releaseDirectory+"/"+release+"/"+"NumberOfFunctions.csv") as f:
            reader = csv.reader(f)
            line= list(reader)
            NumberOfFunctions.append(line[0])
        with open(releaseDirectory+"/"+release+"/"+"BasicBlocksPerFunction.csv") as f:
            reader = csv.reader(f)
            line= list(reader)
            BasicBlocksPerFunction.append(line[0])
        with open(releaseDirectory+"/"+release+"/"+"InstructionsperBasicBlock.csv") as f:
            reader = csv.reader(f)
            line= list(reader)
            InstructionsperBasicBlock.append(line[0])
        with open(releaseDirectory+"/"+release+"/"+"LoadInstructionsperBasicBlock.csv") as f:
            reader = csv.reader(f)
            line= list(reader)
            LoadInstructionsperBasicBlock.append(line[0])
        with open(releaseDirectory+"/"+release+"/"+"StoreInstructionsperBasicBlock.csv") as f:
            reader = csv.reader(f)
            line= list(reader)
            StoreInstructionsperBasicBlock.append(line[0])
        with open(releaseDirectory+"/"+release+"/"+"otherInstructionsPerBasicBlock.csv") as f:
            reader = csv.reader(f)
            line= list(reader)
            otherInstructionsPerBasicBlock.append(line[0])
        with open(releaseDirectory+"/"+release+"/"+"InstructionsPerFunction.csv") as f:
            reader = csv.reader(f)
            line= list(reader)
            InstructionsPerFunction.append(line[0])
        with open(releaseDirectory+"/"+release+"/"+"LoadInstructionsPerFunction.csv") as f:
            reader = csv.reader(f)
            line= list(reader)
            LoadInstructionsPerFunction.append(line[0])
        with open(releaseDirectory+"/"+release+"/"+"StoreInstructionsPerFunction.csv") as f:
            reader = csv.reader(f)
            line= list(reader)
            StoreInstructionsPerFunction.append(line[0])
        with open(releaseDirectory+"/"+release+"/"+"otherInstructionsPerFunction.csv") as f:
            reader = csv.reader(f)
            line= list(reader)
            otherInstructionsPerFunction.append(line[0])

    




        

    with open(releaseDirectory+"NumberOfFunctions.csv", "w") as f:
        writer = csv.writer(f)
        for line in NumberOfFunctions:
            writer.writerows([line])
    with open(releaseDirectory+"BasicBlocksPerFunction.csv", "w") as f:
        writer = csv.writer(f)
        for line in BasicBlocksPerFunction:
            writer.writerows([line])
    with open(releaseDirectory+"InstructionsperBasicBlock.csv", "w") as f:
        writer = csv.writer(f)
        for line in InstructionsperBasicBlock:
            writer.writerows([line])
    with open(releaseDirectory+"LoadInstructionsperBasicBlock.csv", "w") as f:
        writer = csv.writer(f)
        for line in LoadInstructionsperBasicBlock:
            writer.writerows([line])
    with open(releaseDirectory+"StoreInstructionsperBasicBlock.csv", "w") as f:
        writer = csv.writer(f)
        for line in StoreInstructionsperBasicBlock:
            writer.writerows([line])
    with open(releaseDirectory+"otherInstructionsPerBasicBlock.csv", "w") as f:
        writer = csv.writer(f)
        for line in otherInstructionsPerBasicBlock:
            writer.writerows([line])
    with open(releaseDirectory+"InstructionsPerFunction.csv", "w") as f:
        writer = csv.writer(f)
        for line in InstructionsPerFunction:
            writer.writerows([line])
    with open(releaseDirectory+"LoadInstructionsPerFunction.csv", "w") as f:
        writer = csv.writer(f)
        for line in LoadInstructionsPerFunction:
            writer.writerows([line])
    with open(releaseDirectory+"StoreInstructionsPerFunction.csv", "w") as f:
        writer = csv.writer(f)
        for line in StoreInstructionsPerFunction:
            writer.writerows([line])
    with open(releaseDirectory+"otherInstructionsPerFunction.csv", "w") as f:
        writer = csv.writer(f)
        for line in otherInstructionsPerFunction:
            writer.writerows([line])