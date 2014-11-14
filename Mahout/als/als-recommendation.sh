#!/bin/bash

# Convert Ratings
cat $1 |sed -e s/::/,/g| cut -d, -f1,2,3 > ratings.csv

hadoop fs -mkdir movielens
hadoop fs -mkdir dataset 
hadoop fs -mkdir als 
hadoop fs -put ratings.csv movielens/

# create a 90% percent training set and a 10% testing set
$MAHOUT splitDataset --input movielens/ratings.csv --output dataset --trainingPercentage 0.9 --probePercentage 0.1 --tempDir dataset/tmp

# run distributed ALS-WR to factorize the rating matrix defined by the training set
$MAHOUT parallelALS --input dataset/trainingSet/ --output als/out --tempDir als/tmp --numFeatures 20 --numIterations 2 --lambda 0.065 --numThreadsPerSolver 2

# compute predictions against the probe set, measure the error
mahout evaluateFactorization --input dataset/probeSet/ --output als/rmse/ --userFeatures als/out/U/ --itemFeatures als/out/M/ --tempDir als/tmp

# make  recommendations
mahout recommendfactorized --input als/out/userRatings/ --output recommendations/ --userFeatures als/out/U/ --itemFeatures als/out/M/ --numRecommendations 6 --maxRating 5 --numThreads 2

# print RMSE
echo -e "\nRMSE is:\n"
hadoop fs -cat als/rmse/rmse.txt
echo -e "\n"
