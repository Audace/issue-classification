library(randomForest)
library(pROC)

library(tm)
library(SnowballC)

library(RColorBrewer)
library(wordcloud)
library(glmnet)
library(RTextTools)

dir="/Users/williamfry/Development/stat471/code/Final\ Project/"
setwd(dir)

set.seed(1)
data.repos=read.csv("repos.csv", as.is=TRUE)
data.issues=read.csv("issues.csv", as.is=TRUE)

sum(is.na(data.repos))

# Find which repos are not largely written in Python
bad.id = data.repos$id[which(data.repos$lang != "Python")]
data.repos = data.repos[!(data.repos$id == bad.id),]

# Remove top result which is just a compilation of resources
data.repos = data.repos[!(data.repos$id == 21289110),]

# Take repos for which issue pull was run
data.repos = data.repos[1:600,]

# Set closed issues count
data.repos$closed_issues_count <- 0
for (i in 1:length(data.repos$id))
{
  data.repos[i,]$closed_issues_count <- sum(data.issues$repo_id == data.repos[i,]$id)
}

# Set total issues count
data.repos$total_issues_count <- data.repos$open_issues_count + data.repos$closed_issues_count

# Take issues that belong to top 500 cleaned repos
data.issues.clean = data.issues[(data.issues$repo_id %in% data.repos$id),]

# Check if any are empty
sum(is.na(data.issues.clean))

# As numeric
data.issues.clean$issue_comments = as.integer(data.issues.clean$issue_comments)

# Mark issues as including a code block if triple-ticks present in body
has_code <- "```"
data.issues.clean$has_code_block <- 0
data.issues.clean$has_code_block[grepl(has_code, data.issues.clean$body) == "TRUE"] <- 1
data.issues.clean$has_code_block <- as.factor(data.issues.clean$has_code_block)

# Get length of body
data.issues.clean$body_size = as.integer(nchar(data.issues.clean$body))

# For each repo, calculate the open, closed, and total issue counts. Create variable and set value for children issues
for (i in 1:length(data.repos$id))
{
  data.issues.clean$repo_open_issues_count[data.issues.clean$repo_id == data.repos[i,]$id] <- as.integer(data.repos[i,]$open_issues_count)
  data.issues.clean$repo_closed_issues_count[data.issues.clean$repo_id == data.repos[i,]$id] <- as.integer(data.repos[i,]$closed_issues_count)
  data.issues.clean$repo_total_issues_count[data.issues.clean$repo_id == data.repos[i,]$id] <- as.integer(data.repos[i,]$total_issues_count)
}

# Group issue labels into those that are bugs / critical and those that are not
unique(unlist(data.issues.clean$label1, use.names = FALSE))
unique(unlist(data.issues.clean$label2, use.names = FALSE))
unique(unlist(data.issues.clean$label3, use.names = FALSE))
unique(unlist(data.issues.clean$label4, use.names = FALSE))
unique(unlist(data.issues.clean$label5, use.names = FALSE))
unique(unlist(data.issues.clean$label6, use.names = FALSE))
unique(unlist(data.issues.clean$label7, use.names = FALSE))
unique(unlist(data.issues.clean$label8, use.names = FALSE))
unique(unlist(data.issues.clean$label9, use.names = FALSE))
unique(unlist(data.issues.clean$label10, use.names = FALSE))
unique(unlist(data.issues.clean$label11, use.names = FALSE))

is_bug <- c("Crash","Prio-High","Effort Medium","Complex","Difficulty Novice","Effort Low","Difficulty Advanced","In Progress","in progress","Bug","bug","Difficulty Intermediate","Difficulty Novice","Complex","important","type: bug","Critical","High Priority","Medium Priority","Difficulty: Easy","confirmed bug","Low Priority","upstream fix required","Release critical","Difficulty: Hard","needs_patch","critical bug","Difficulty: Medium","high","high-priority","please-help","Easy to Fix","Wrong Result","deployment-issue","High priority","Bug - Verified","crisis","highpriority","Priority-High","Priority-Medium","Priority-Low","needs patch","easy fix","type-bug","prio-high","prio-low","AST-generation/bug","MEDIUM","priority","critical","fix in next release","Urgent","bugs","Type-Bug","Confirmed Bug","Fix in progress","Fix commited","error/bug","complexity-medium","complexity-high","complexity-low","major","being worked on","Priority","quickfix","Accepted","need contributor!","patch wanted","priority-low","priority-normal","priority-high","help required","help wanted","medium","prio:low","difficulty/low","api-breakage","bug-fixed","Bug Report","reso: completed","Breaking API Change","smallfixes","Difficulty: Hard","(2) in progress","Fixed","Wrong Result","Easy to Fix","Effort Low","Valid","Resolved for Next Version")

# Set status to zero
data.issues.clean$status = 0

# Set status to 1 if one of the 11 different labels referneces a critical bug
data.issues.clean$status[data.issues.clean$label1 %in% is_bug | data.issues.clean$label2 %in% is_bug | data.issues.clean$label3 %in% is_bug | data.issues.clean$label4 %in% is_bug | data.issues.clean$label5 %in% is_bug |
                           data.issues.clean$label6 %in% is_bug | data.issues.clean$label7 %in% is_bug |
                           data.issues.clean$label8 %in% is_bug | data.issues.clean$label9 %in% is_bug |
                           data.issues.clean$label10 %in% is_bug | data.issues.clean$label11 %in% is_bug] = 1

# Set status as factor
data.issues.clean$status = as.factor(data.issues.clean$status)

hist(data.repos$stars, breaks=25, main="Histogram of Stars per Repo",xlab="Number of Stars")
summary(data.repos$stars)

hist(data.repos$watching, breaks=25, main="Histogram of Developers Watching a Repo",xlab="Developers Watching")

hist(data.repos$forked, breaks=25, main="Histogram of Forks per Repo",xlab="Times Forked")

hist(data.repos$open_issues_count, breaks=25, main="Histogram of Open Issues per Repo",xlab="Number of Open Issues")

hist(data.repos$closed_issues_count, breaks=25, main="Histogram of Closed Issues per Repo",xlab="Number of Closed Issues")

hist(data.issues.clean$issue_comments, breaks=25, main="Histogram of Comments per Issues",xlab="Number of Comments")

hist(data.issues.clean$body_size, breaks=25, main="Histogram of Body Size per Issue",xlab="Body Size in Characters")

titlecorpus.1 <- VCorpus( VectorSource(data.issues.clean$title))
# Change to lowercase since it's case-sensitive
titlecorpus.2 <- tm_map(titlecorpus.1, content_transformer(tolower))
# Remove stop words
titlecorpus.3 <- tm_map(titlecorpus.2, removeWords, stopwords("english"))
# Remove punctuation
titlecorpus.4 <- tm_map(titlecorpus.3, removePunctuation)
# Remove numbers
titlecorpus.5 <- tm_map(titlecorpus.4, removeNumbers)
# Stem words
titlecorpus.6 <- tm_map(titlecorpus.5, stemDocument, lazy = TRUE) 

dtm.title.1 <- DocumentTermMatrix(titlecorpus.6)

# Set threshold to 2% of the total documents 
threshold=.02*length(titlecorpus.6)
# Words appearing at least among 2% of the documents
words <- findFreqTerms(dtm.title.1, lowfreq=threshold)
# Update DocumentTermMatrix with threshold at 2%
dtm.title.2<- DocumentTermMatrix(titlecorpus.6, control=list(dictionary = words))

bodycorpus.1 <- VCorpus( VectorSource(data.issues.clean$body))
# Change to lowercase since it's case-sensitive
bodycorpus.2 <- tm_map(bodycorpus.1, content_transformer(tolower))
# Remove stop words
bodycorpus.3 <- tm_map(bodycorpus.2, removeWords, stopwords("english"))
# Remove punctuation
bodycorpus.4 <- tm_map(bodycorpus.3, removePunctuation)
# Remove numbers
bodycorpus.5 <- tm_map(bodycorpus.4, removeNumbers)
# Stem words
bodycorpus.6 <- tm_map(bodycorpus.5, stemDocument, lazy = TRUE) 

dtm.body.1 <- DocumentTermMatrix(bodycorpus.6)

# Set threshold to 2% of the total documents 
threshold=.02*length(bodycorpus.6)
# Words appearing at least among 2% of the documents
words <- findFreqTerms(dtm.body.1, lowfreq=threshold)
# Update DocumentTermMatrix with threshold at 2%
dtm.body.2<- DocumentTermMatrix(bodycorpus.6, control=list(dictionary = words))

# Find top 5 most frequent words in title
findFreqTerms(dtm.title.2, 1000)

# Find top 5 most frequent words in body
findFreqTerms(dtm.body.2, 9000)

# Create data frame with variables and both DTMs
data.go=data.frame(data.issues.clean,as.matrix(dtm.title.2),as.matrix(dtm.body.2))

n=nrow(data.go)
# Reserve 20% for testing
test.index=sample(n, 25890*.2)
data.go=data.go[-c(1:4,6:17)]
data.go.test=data.go[test.index,]
data.go.train=data.go[-test.index,]

# Take out status for y
y=data.go.train[, 7]
X=data.matrix(data.go.train[, -c(7)])
# Get lambdas
result.lasso=cv.glmnet(X, y, alpha=.99, family="binomial")
# Plot lambdas against binomial deviance
plot(result.lasso)
# Number of non-zeros for lambda.min
sum(which(coef(result.lasso, s="lambda.min")!=0))
# Number of non-zeros for lambda.1se
sum(which(coef(result.lasso, s="lambda.1se")!=0))

beta.lasso=coef(result.lasso, s="lambda.1se")
# Get non-zero betas
beta=beta.lasso[which(beta.lasso !=0),]
beta=as.matrix(beta)
# Get names of non-zero coefficients
beta=rownames(beta)

# Configure input
glm.input=as.formula(paste("status", "~", paste(beta[-1],collapse = "+")))
# Run logistic regression using non-zero coefficients
result.glm=glm(glm.input, family=binomial, data.go.train)
result.glm.coef=coef(result.glm)

# Take out coefficients that come from DTM (non-variable ones)
result.glm.coef=result.glm.coef[5:88]

# Take out positive word coefficients
positive.coef=result.glm.coef[which(result.glm.coef > 0)]
# Sort by largest
positive.coef.sorted=sort(positive.coef, decreasing = TRUE)

good.word=names(positive.coef.sorted)
cor.special=brewer.pal(8,"Dark2")
# Create wordcloud for positively correlated words
wordcloud(good.word, positive.coef.sorted,
          colors=cor.special, ordered.colors=F)

# Take out negative coefficients
negative.coef=result.glm.coef[which(result.glm.coef < 0)]
# Sort by largest
negative.coef.sorted=sort(negative.coef, decreasing = FALSE)

bad.word=names(negative.coef.sorted)
cor.special=brewer.pal(6,"Dark2")
# Create wordcloud for negatively correlated words
wordcloud(bad.word, -negative.coef.sorted,
          colors=cor.special, ordered.colors=F)

predict.glm=predict(result.glm, data.go.test, type="response")
class.glm=rep("0", 25890*.2)
class.glm[predict.glm > .5] ="1"

# Get MCE for glm
testerror.glm=mean(data.go.test$status != class.glm)

# Plot the ROC
roc(data.go.test$status, predict.glm, plot=T)

# Show confusion matrix
table(class.glm, data.go.test$status)

# Setup RTextTools
X = data.matrix(data.go[, -c(7)])
container=create_container(X, 
                           labels=data.go$status,
                           testSize=test.index,
                           virgin=FALSE)

# Run GLMNET with RTextTools
model_glmnet=train_model(container, "GLMNET")
glmnet_out=classify_model(container, model_glmnet)
glmnet_mce=mean(data.go$status[test.index] != glmnet_out[, 1])

table(glmnet_out[, 1], data.go.test$status)

# Run RF with RTextTools
model_RF=train_model(container, "RF")
RF_out=classify_model(container, model_RF)
RF_mce=mean(data.go$status[test.index] != RF_out[, 1])

table(RF_out[, 1], data.go.test$status)

# Run BOOSTING with RTextTools
model_BOOSTING=train_model(container, "BOOSTING")
BOOSTING_out=classify_model(container, model_BOOSTING)
BOOSTING_mce=mean(data.go$status[test.index] != BOOSTING_out[, 1])

table(BOOSTING_out[, 1], data.go.test$status)

# Run SVM with RTextTools
model_SVM=train_model(container, "SVM")
SVM_out=classify_model(container, model_SVM)
SVM_mce=mean(data.go$status[test.index] != SVM_out[, 1])

table(SVM_out[, 1], data.go.test$status)

# Compare all four MCEs
data.frame(glmnet_mce, RF_mce, BOOSTING_mce, SVM_mce)

# Regression with Random Forest
fit.rf=randomForest(status~., data.go.train, xtest=data.go.test[, -c(7)], 
                    ytest=data.go.test[,7], ntree=100)
# Calculate MSE
mean(fit.rf$mse)
# Plot the number of trees against error
plot(fit.rf)
# Get summary statistics
summary(fit.rf)
# Create matrix of importance
var_importance <- as.matrix(importance(fit.rf))
# Order variables by importance and grab top 10
var_importance[order(-var_importance[,1]),][1:10]

# Classification
fit.rf.class=randomForest(status~., data.go.train, ntree=100)
# Predict labels
fit.rf.pred.y=predict(fit.rf.class,newdata=data.go.test)
# Calculate MCE
mean(data.go.test$status != fit.rf.pred.y)