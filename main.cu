#include<cstdio>
#include <omp.h> // OpenMP
#include <mpi.h> // MPI Interface

__global__ void cuda_hello(){
    printf("Hello World from GPU!\n");
}

int main() {
	// Stock CPP
	printf("Hello World from CPU (CPP)!\n");

	// MPI
	MPI_Init(NULL, NULL);
	int world_size; MPI_Comm_size(MPI_COMM_WORLD, &world_size);
	int world_rank; MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);
	char processor_name[MPI_MAX_PROCESSOR_NAME]; int name_len;
	MPI_Get_processor_name(processor_name, &name_len);
	printf("Hello world from processor %s, rank %d out of %d processors\n",
		processor_name, world_rank, world_size);
	MPI_Finalize();

	// OpenMP*
#pragma omp parallel                   
{
    printf("Hello World... from thread = %d/%d\n", 
           omp_get_thread_num(), omp_get_max_threads() );
} 

	// CUDA
	cuda_hello<<<1,1>>>();
	cudaDeviceSynchronize();

	return 0;
}
