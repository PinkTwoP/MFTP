import os
import numpy as np
import mat4py as mp
import scipy.io as scio
import warnings

warnings.filterwarnings('error')





def external_control_source(OUTPUTPATH,OUTPUTFILENAME):
	fo = open(OUTPUTPATH+OUTPUTFILENAME,mode ='r')
	content = fo.readlines()
	fo.close()
	external_sources_number = int(content[0][29:-2])
	external_sources = np.zeros((external_sources_number,1), dtype = np.int64)
	k = 0
	for i in range(len(content)):
		temp_char = ''
		if str.isdigit(content[i][0]):
			for j in range(len(content[i])):
				if str.isdigit(content[i][j]):
					temp_char = temp_char + content[i][j] 
				else:
					break
			external_sources[k] = int(temp_char)
			k = k + 1
		if k == external_sources_number:
			break 

	control_circles = []
	for i in range(3+external_sources_number,len(content)):
		temp_char = ''
		for j in range(len(content[i])):
			if str.isdigit(content[i][j]):
				temp_char = temp_char + content[i][j] 
			else:
				break 
		control_circles.append(int(temp_char))
	control_circles_number = len(control_circles)
	return external_sources, external_sources_number, control_circles,control_circles_number



def netdata2net(netdata,network_size):
	netdata_shape = netdata.shape
	net = np.zeros((network_size,network_size),dtype = np.int64)
	for i in range(netdata_shape[0]):
		net[netdata[i][1]-1][netdata[i][0]-1] = 1
	return net

def controlMatrix(network_size,OUTPUTPATH,OUTPUTFILENAME):
	external_sources, external_sources_number, control_circles,control_circles_number = external_control_source(OUTPUTPATH,OUTPUTFILENAME)
	B = np.zeros((network_size,external_sources_number),dtype = np.int64)
	for i in range(external_sources_number):	
		B[external_sources[i][0]-1][i] = 1
	# if control_circles_number == 0
	for i in range(control_circles_number):
		if i % external_sources_number != i:
			B[control_circles[i]-1][i%external_sources_number] = 1

		else:
			B[control_circles[i]-1][i] = 1
	return B

def loadNetData(NETWORKPATH,NETWORKNAME):
	data = mp.loadmat(NETWORKPATH+NETWORKNAME)
	netdata = np.array(data['A'])
	network_size = int(netdata.max())
	return netdata, network_size

def subsetRead(SUBSETPATH,SUBSETNAME,network_size):
	fo = open(SUBSETPATH + SUBSETNAME, mode = 'r')
	content = fo.readlines()
	fo.close()
	ss_str = content[-2].split(' ')[0:-1]
	ss_number = len(ss_str)
	subset = np.zeros((ss_number,1),dtype = np.int64)
	for i in range(ss_number):
		subset[i][0] = int(ss_str[i])
	C = np.zeros((ss_number,network_size), dtype = np.int64)
	for i in range(ss_number):
		C[i][subset[i][0]-1] = 1

	return C,ss_number

def controllabilityMatrix(A,B,C,comprodA):
	CM = np.dot(C,B)
	network_size = A.shape[0]
	for i in range(network_size-1):
		temp = np.dot(comprodA[str(i+1)],B)
		CM = np.hstack((CM,np.dot(C,temp)))

	MM = matrxBuildinProd(C,B)
	network_size = A.shape[0]
	for i in range(network_size-1):
		temp = matrxBuildinProd(comprodA[str(i+1)],B)
		MM = np.hstack((MM,matrxBuildinProd(C,temp)))



	return CM,MM



def matrixComprod(matrix,number):
	temp = matrix
	output = {'1':temp}
	for i in range(number-1):
		temp = np.dot(matrix,temp)
		output[str(i+2)] = temp
	return output

# this function aims to catch value overflows 
def matrxBuildinProd(matA,matB): 
	dim11 = matA.shape[0]
	dim12 = matA.shape[1]
	dim21 = matB.shape[0]
	dim22 = matB.shape[1]
	matC = np.zeros((dim11,dim22),dtype=np.int64)
	for i in range(dim11):
		for j in range(dim22):
			temp = 0;
			for k in range(dim12):
				# throw a warning when the value overflows
				# which indicates the result is invalid
				try:
					temp = temp + matA[i][k]*matB[k][j]
					# warnings.warn(Warning())
				except RuntimeWarning as e:
					print(matA[i][k],matB[k][j])

			matC[i][j] = temp
	return matC


	
if __name__=='__main__':

	# the network data
	NETWORKPATH = os.getcwd()+'\\'
	NETWORKNAME = 'Rand_Network_20node_3meandegree.mat'
	netdata, network_size = loadNetData(NETWORKPATH,NETWORKNAME)

	# the network adjacent matrix
	A = netdata2net(netdata,network_size) 

	# compute and store the result of A**0, A**1, A**2,...,A**(N-1)
	comprodA = matrixComprod(A, network_size-1)
	for i in range(5,25,5):
		SUBSETSIZE = str(i)

		# the output result from MFTP algorithm
		OUTPUTPATH = os.getcwd()+'\\'
		OUTPUTFILENAME = 'Output203('+SUBSETSIZE+').txt'
		print(OUTPUTFILENAME)
		
		# the nodes list of target control subset
		SUBSETPATH = os.getcwd()+'\\'
		SUBSETNAME = 'Input203('+SUBSETSIZE+').txt'
		
		# the input matrix B
		B = controlMatrix(network_size,OUTPUTPATH,OUTPUTFILENAME) 
		# the ouput matrix based on target control subset
		C,ss_number = subsetRead(SUBSETPATH,SUBSETNAME,network_size)

		# CM obtained by np.dot and MM obtained by build-in function which aims to 
		# catch value overflow warnings. 
		# When the size of networks becomes larger, the result is invalid because 
		# of the value overflow (in this case, we test 20-node random network).
		CM,MM = controllabilityMatrix(A,B,C,comprodA)
		rankCM = np.linalg.matrix_rank(CM)
		rankMM = np.linalg.matrix_rank(MM)
		_, singular_value_matrix, _ = np.linalg.svd(CM)
		min_singular_value = singular_value_matrix[-1]
		subset_size = C.shape[0]
		print('the size of subset is ',subset_size)
		print('the rank of controllability matrix via np.dot is ',rankCM)
		print('the rank of controllability matrix via matrxBuildinProd is ',rankMM)
		print('the minimum sigurlar value of controllability matrix is ',min_singular_value)







