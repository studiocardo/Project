library(dplyr)

#
# set the working directory to original level
#
orgwd<-getwd()

#
# Check to ensure the necessary data source files are present
#
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"

dataset <- "UCI HAR Dataset"
gotdata <- file.exists(dataset)
if (!gotdata) {
    download.file(url, destfile = "dataset.zip", method = "curl")
    unzip("dataset.zip")
    file.remove("dataset.zip")
}

#
# Read in the data from various source files
#
setwd(file.path(orgwd, dataset, sep="/"))

classes <- c("integer", "character")
features <- read.table("features.txt", colClasses=classes, stringsAsFactors = FALSE)

activity <- c("labelIndex", "labelName")
activity_labels <- read.table("activity_labels.txt", colClasses=classes, stringsAsFactors = FALSE, col.names = activity)

#
# Change wd to train so simplifies reading the files
#
setwd(file.path(orgwd, dataset, "train", sep="/"))

x_train_df <- read.table("X_train.txt", colClasses="numeric", check.names = TRUE)
y_train_df <- read.table("y_train.txt", colClasses="integer", col.names="Activity", check.names = TRUE)
subject_train_df <- read.table("subject_train.txt", colClasses="integer", col.names="Subject", check.names = TRUE)

# Change wd to test so simplifies reading the files
#
setwd(file.path(orgwd, dataset, "test", sep="/"))

x_test_df <- read.table("X_test.txt", colClasses="numeric", check.names = TRUE)
y_test_df  <- read.table("y_test.txt",  colClasses="integer", col.names="Activity", check.names = TRUE)
subject_test_df  <- read.table("subject_test.txt",  colClasses="integer", col.names="Subject", check.names = TRUE)

	# go back to original wd
	#
	setwd(orgwd)

	#
	# Convert the dataframes into dplyr structures
	#
	x_train<-tbl_df(x_train_df)
	x_test <-tbl_df(x_test_df)

	y_train<-tbl_df(y_train_df)
	y_test <- tbl_df(y_test_df)

	subject_train <- tbl_df(subject_train_df)
	subject_test  <- tbl_df(subject_test_df)

		#
		# Delete all dataframes to save memory
		#
		rm(x_train_df)
		rm(x_test_df)

		rm(y_train_df)
		rm(y_test_df)

		rm(subject_train_df)
		rm(subject_test_df)

#
# Instead of the usual rbind, using the dplyr option of bind_rows
#
x <- bind_rows (x_test, x_train)
y <- bind_rows (y_test, y_train)
subject <- bind_rows (subject_test, subject_train)

#
# Now we are going to add the column names to x and y
# I chose not to use option col.names=feature[,2] because R fucks w/ column names when doing read.
# It replaces '-', ' ', '()' to .
#
# http://stackoverflow.com/questions/17152483/how-to-replace-the-in-column-names-generated-by-read-csv-with-a-single-spa
#

measurement <- features[,2]
names(x) <- measurement

#
# Freaky what you can do w/ mutate...  A little testing is required to gain confidence on how dplyr does things...
# Take whatever observation value is in the column Activity and use that as an index for the activity_labels to retrieve
# the string value of that activity_labels observation and apply that back into the observation of Activity in y
#
y <- mutate(y, Activity = activity_labels[Activity, 2])

#
# We can extract the mean|std columns first then combine that with subject/activity table or combine first then extract
# Going to combine them first
# Instead of standard cbind, going to try bind_col
#
# subject
# y = activity
# x = data

cran <- bind_cols(subject, y, x)

#
# get only mean() or std() of each measurement
# and that is presented in the format of xxxx-mean() or xxx-std()
#
# Need to include Subject and Activity, or they get left out of the grep
#

query = "Subject|Activity|-(mean|std)\\(\\)"

candy <- cran[, grepl(query, names(cran))]

#
# From the data set in step 4, creates a second, 
# independent tidy data set with the average of each variable for each activity and each subject.
# 

# The killer function for this task is summarise_each...  Note it's summarise with a 's', not summarize with a 'z'
# Do ?summarise_each in RStudio to see how it works
#
meancandy <- candy %>% 
	group_by(Subject, Activity) %>% 
	summarise_each(funs(mean))

#
# Write the output to the files tidydata.txt in the working directory 
#
write.table(meancandy, "tidydata.txt", row.name=FALSE)

