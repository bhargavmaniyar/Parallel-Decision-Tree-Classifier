#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <sstream>

#include "math.h"
#include "limits.h"

#define trainingData "myDataset.txt"
#define testingData "myDataset.txt"
#define M 6
#define N 14
#define trainFileData(row,col) trainFileData[row*M+col]
#define testFileData(row,col) testFileData[row*M+col]

using namespace std;

vector <vector <int> > trainFile;
vector <vector <int> > testFile;

int *d_trainFileData, *d_cardinality;

dim3 blocks(M);
dim3 threads(M,N);

// node structure of the decision tree
// attribute: splitting attribute (= -1 if leaf node)
// val: class value at leaf node (= -1 if decision node)
// branchVal: make branch decision based on this value
struct Node{
	int numOfChildren;
	int val;
	int branchVal;
	int attribute;
	struct Node *child[10];
};

typedef struct Node node;

// initialising tree node
node* create(){
	node* n = new node;
	n->numOfChildren = 0;
	n->attribute = -1;
	n->val = -1;
	n->branchVal = -1;
	return n;
}

// function to read data and store in fileContent & testFileContent vectors(2d)
void readCSV(string str)
{
	// input file stream (ifs) for reading data from file
	if(str.compare("training")==0){
		ifstream ifs(trainingData);
		string line;

		// read from ifs into string 'line'
		while(getline(ifs,line)){
			stringstream lineStream(line);
			string cell;
			vector <int> values;
			// collecting row data from file delimited by ','
			while(getline(lineStream,cell,',')){
				const char *cstr = cell.c_str();
				values.push_back(atoi(cstr));
			}
			fileContent.push_back(values);
		}
		ifs.close();
	}
	else if(str.compare("testing")==0){
		ifstream ifs(testingData);
		string line;
		
		// read from ifs into string 'line'
		while(getline(ifs,line)){
			stringstream lineStream(line);
			string cell;
			vector <int> values;
			// collecting row data from file delimited by ','
			while(getline(lineStream,cell,',')){
				const char *cstr = cell.c_str();
				values.push_back(atoi(cstr));
			}
			testFileContent.push_back(values);
		}
		ifs.close();
	}
}

__global__


void decision(int *h_attr,int *h_data, node* root,int h_dataSize)
{
	int flag,h_selectedAttribute,i;
	if(h_dataSize==0){
		return;
	}
	flag=1;
	for(i=1;i<h_dataSize;i++){
		if(trainFile[h_data[i]][M-1]!=trainFile[h_data[i-1]][M-1]){
			flag=0;
			break;
		}
	}
	if(flag==1){
		root->val=trainFile[h_data[0]][M-1];
		return;
	}

	int *d_attr, *d_data, *d_selectedAttribute;

	cudaMalloc((void**)&d_attr,M*sizeof(int));
	cudaMalloc((void**)&d_data,h_dataSize*sizeof(int));
	cudaMalloc((void**)&d_selectedAttribute,sizeof(int));
	cudaMemcpy((void*)d_attr,(void*)h_attr,M*sizeof(int),cudaMemcpyHostToDevice);
	cudaMemcpy((void*)d_data,(void*)d_data,N*sizeof(int),cudaMemcpyHostToDevice);

	select<<<>>>
	
}

__global__ void getCardinality(int *trainFileData,int *cardinality)
{
	__shared__ int x[10];
	int bid,tid;
	unsigned int i;
	bid=blockIdx.x;
	tid=threadIdx.x;
	if(tid<10){
		x[tid]=0;
	}
	__syncthreads();
	x[trainFileData(tid,bid)]==1;
	__syncthreads();
	for(i=1;i<10;i*=2){
		int index = 2*i*tid;
		if(index+i<10){
			x[index]+=x[index+i];
		}
		__syncthreads();
	}
	if(tid==0){
		cardinality[bid]=x[0];
	}
}

int main()
{
	int i;
	node* root;

	readCSV("training");

	int h_trainFileData[N*M];

	for(i=0;i<N*M;i++){
		h_trainFileData[i] = trainFile[i/M][i%M];
	}

	int h_data[N],h_attr[M];

	for(i=0;i<N;i++){
		h_data[i]]=i;
	}

	for(i=0;i<M;i++){
		h_attr[i]=0;
	}

	cudaMalloc((void**)&d_trainFileData,N*M*sizeof(int));
	cudaMemcpy((void*)d_trainFileData,(void*)h_trainFileData,M*N*sizeof(int),cudaMemcpyHostToDevice);

	cudaMalloc((void**)&d_cardinality,M*sizeof(int));
	cudaMemset(d_cardinality,0,M*sizeof(int));
	getCardinality<<<blocks,threads>>>(d_trainFileData,d_cardinality);

	root = create();
	decision(h_attr,h_data,root,N);

	return 0;
}