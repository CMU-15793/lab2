# Lab 2

## Introduction

The goal of this lab is to design a privacy-preserving key-value store using a technique that we learned in class: private information retrieval (PIR). PIR is a cryptographic technique for a client to retrieve an item from a public database hosted on a server, without revealing the location of the item to the server. In this lab, we will use another technique that we learned in class -- BFV homomorphic encryption -- to construct our protocol.

## Background

In this lab, you will build a small distributed system that consists of a client and a server. The code will make use of two libraries: 

* [OpenFHE](https://github.com/openfheorg/openfhe-development) is an open-source library for homomorphic encryption. It implements a few popular variants of FHE. In this project we will use the BFV encryption scheme.
* [gRPC](https://github.com/grpc/grpc) is a popular open-source library for remote procedure calls (RPC). We will be using gRPC as a way to communicate between the client and the server.

A Dockerfile has been provided for you with the dependencies and libraries installed. 

### BFV

BFV is a recent state-of-the-art FHE scheme that leverages the ring learning with errors (RLWE) assumption. The main advantage of a scheme like BFV is that a single ciphertext can encrypt plaintext *vectors* where the vector values are small integers. Because of this, BFV also supports single instruction multiple data (SIMD) operations, such as SIMD additions and SIMD multiplications. Therefore, a single ciphertext addition (multiplication) actually produces the element-wise sum (product) of the underlying plaintext vectors.

BFV also supports limited data movement operations. Specifically, a homomorphic rotation operation can rotate the underlying plaintext vector. One important thing to note is that BFV actually supports _2D rotations_ instead of 1D rotations. A ciphertext that encrypts a vector of `N = 1024` plaintext values `[1, 2, ..., 1024]` can be rotated along two dimensions of size N/2x2. This means that rotating a ciphertext by 1 along dimension 0 gives `[512, 1, 2, ..., 511, 1024, 513, 514, ..., 1023]`. You can also rotate along dimension 1, which will give you `[1024, 513, 514, ..., 1023, 512, 1, 2, ..., 511]`. See this [thread](https://openfhe.discourse.group/t/rotation-in-bfv/416) for some more information. 

### Private information retrieval (PIR)

PIR is a technique for privately reading information from a publicly hosted database. There are two parties in the protocol: the client and the server. The client is trusted, while the server is a semihonest adversary who attempts to learn what data the client wants to retrieve from the server. In our setting, we assume that the database has $M$ rows, and the API we want to implement is `ReadRow(i)`. Client can call `ReadRow(i)` to retrieve the content of row `i`. Our goal is to implement a cryptographic protocol to hide the value of `i`.

In an insecure design, the client gives `i` to the server in plaintext. The server immediately learns the value of `i`.

In PIR, the client instead gives an encrypted query to the server. Intuitively, `i` is encrypted using homomorphic encryption so that the server does not learn what the value of `i` is, but the server can still operate on its database using this encrypted query thanks to the properties of homomorphic encryption.

### Using Docker

As part of the lab, we are providing you with a Dockerfile so that you can easily do your development in this environment. Your code will be tested in this environment. 

First, download the latest version of [Docker](https://www.docker.com/). 

* Build Docker image using the Docker file: `docker build -t <image_name> -f <path_to_dockerfile> .`
* Start a Docker container from the image: `docker run -it --name <container_name> <image_name>`
* You might want to mount your code into the container using the `-v` flag. You can do this by running `docker run -it -v <path_to_code_repo>:<path_in_container> <container_name>`
* To start multiple terminals of the same container, run `docker exec -it <container_name> /bin/bash`

### Getting started with the libraries

> **Task 0.1**: go through the [`simple-integers.cpp`](https://github.com/openfheorg/openfhe-development/blob/main/src/pke/examples/simple-integers.cpp) and [`simple-integers-serial.cpp`](https://github.com/openfheorg/openfhe-development/blob/main/src/pke/examples/simple-integers-serial.cpp) examples to get familiar with the OpenFHE API calls. 

> **Task 0.2**: go through the gRPC [hello world](https://grpc.io/docs/languages/cpp/quickstart/) example and familiarize yourself with the gRPC APIs.


## Lab

### System setup

The server hosts a database of size 1048576 rows. Each row is initialized with a small integer value such that row `i`'s value is `i`. The client wants to retrieve a row `i` without revealing which row was retrieved from the server.

We have provided you some starter client and server code, as well as the appropriate CMake file and proto buffer definitions. The code is organized as follows:

* `src/pir_client_template.cc`: starter code for the PIR client.
* `src/pir_server_template.cc`: starter code for the PIR server.
* `src/CMakeLists.txt`: the CMake file for src.
* `protos/`: proto definitions used for gRPC.
* `keys/`: pre-generated sample key pair. 

To build the initial template code, create a build directory in the root directory by calling `mkdir build`. Then call `cd build; cmake ../; make` to build the binaries, which will be located under `build/src`. 

You can restructure the initial code, as long as you have implementations for a PIR client and a PIR server. The client should also have some kind of user-facing API to run a query, such as `uint32_t ReadRow(uint32_t i)`. You are responsible for writing your own tests, and these tests should be turned in along with your PIR implementation. 

### Deliverables

* Code implementation, as well as a comprehensive test suite.
* PDF writeup with answers to the questions.


### Part 1: Getting familiar with FHE parameters (10%)

> **Task 1.1**: Sample public and private keys are given to you in the repository. For the sample key parameters, how many slots are supported in a single ciphertext? How big is the plaintext modulus? How big is one ciphertext? (5%)

> **Task 1.2**: Generate one rotation key for rotation of size 1 and write it out as a file to the same directory. (5%)

> **Task 1.3 (Optional)**: The sample parameters are not necessarily optimized. You can feel free to generate your own BFV parameters, and use them for the rest of the systems implementation. If you choose to optimize for the FHE parameters, then explain what are the FHE parameters that you are using. 


### Part 2: Naive design for PIR with linear-sized queries (40%)

In this initial (warm-up) design, you will implement a naive PIR design that uses linear-sized queries on a database of size 1048576. The idea is very simple. First, the server should arrange database into a table with of 1048576 rows. Then, the client should generate a linear-sized query that is a one-hot encoding of the desired row `i`. The query vector `q` should be 0 everywhere except at location `i`: `q[j] = 0` if `j != i`, otherwise `q[j] = 1`. Therefore, the server side encrypted computation is a dot product between the database and the encrypted query. 

You can simplify key management in your implementation by assuming that the client and the server are able to access the appropriate keys by loading them from `keys/`. *The PIR server should not see the private key!!*

> **Task 2.1**: Implement the naive design. (25%)

> **Task 2.2**: How many ciphertexts do you need to encode the query? How many ciphertexts do you need for the response? (5%)

> **Task 2.3**: Report the runtime for a single query. Present a breakdown of the runtime in terms of 1. client compute cost in milliseconds 2. server compute cost in milliseconds 3. communication cost in bytes. Remember to describe your experiment setup (what machine you are using). (10%)

### Part 3: Communication-efficient PIR with sublinear-sized queries (50%)

Linear-sized queries are extremely inefficient. It is possible to significantly improve upon the communication overhead by restructuring the database. For example, a large database in the previous part can be re-structured as a 2D matrix that is 1024x1024. Instead of sending a linear-sized query, one can send an encrypted one-hot encoding query vector that is of length 1024, and retrieve an entire column of the database via matrix-vector multiplication. The client can then select the correct value out of the 1024 values. 

For example, assume that the database is organized row-wise in the matrix: `[[0, 1, 2, ..., 1023], [1024, 1025, 1026, ...], ... ]`. A query for index `1026` should be mapped to a query `(1, 2)`. Therefore, the query should retrieve column 2 via a matrix-vector multiplication. The client receives `[2, 1026, 2050, ...]`, and returns the second value which is `1026`.

*Note that the 2D matrix does not necessarily have to be square. In your implementation, think about what matrix sizes make sense given your FHE key parameters.*

> **Task 3.1**: Implement and explain your sublinear query design in BFV. What is the FHE computation that you need to execute? Explain your algorithm and how you pack the client's query in BFV. (35%)

> **Task 3.2**: How many ciphertexts do you need to encode the query? How many ciphertexts do you need for the response? (5%)

> **Task 3.3**: Report the runtime for a single query. Present a breakdown of the runtime in terms of communication cost and compute cost, similar as Task 2.3. (10%)

