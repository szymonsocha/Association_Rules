# data from one month of operation at a real-world grocery store
# 9,835 transactions, or about 327 transactions per day (roughly 30 transactions per hour in a 12 hour business day)
# adapted from the Groceries dataset in the Apriori R package

# all brand names can be removed from the purchases
# it reduces the number of groceries to a more manageable 169 types, using broad categories 
# such as chicken, frozen meals, margarine, and soda

# transactional data is stored in a slightly different format
# given the usual structure of the matrix format, all examples are required to have exactly the same set of features
# transactional data is more free-form
# usually each row in the data specifies a single example—in this case, a transaction
# each record comprises a comma-separated list of any number of items, from one to many

# sparse matrix
# each row in the sparse matrix indicates a transaction
# there is a column (feature) for every item that could possibly appear in someone's shopping bag

# as additional transactions and items are added, 
# a conventional data structure quickly becomes too large to fit into memory

# sparse matrix does not actually store the full matrix in memory; 
# it only stores the cells that are occupied by an item
# this allows the structure to be more memory efficient than an equivalently sized matrix or data frame

install.packages("arules")
library(arules)

# create a sparse matrix suitable for transactional data
groceries <- read.transactions("groceries.csv", sep = ",")

# inspect the dataset
summary(groceries)

inspect(groceries)

size(groceries) 

length(groceries)

# simple statistics 
itemFrequency(groceries, type="relative")
itemFrequency(groceries, type="absolute")

# 9835 rows refer to the store transactions
# 169 columns are features for each of the 169 different items that might appear in someone's grocery basket
# each cell in the matrix is a 1 if the item was purchased for the corresponding transaction, or 0 otherwise

# density value of 0.02609146 (2.6 percent) refers to the proportion of non-zero matrix cells

# as there are 9835 * 169 = 1662115 positions in the matrix, we can calculate 
# that a total of 1662115 * 0.02609146 = 43367 items were purchased during the store's 30 days of operation 
# assuming no duplicate items were purchased

# the average transaction contained 43367 / 9835 = 4.409 different grocery items

# the function lists the items that were most commonly found in the transactional data
# as 2513 / 9835 = 0.2555, we can determine that whole milk appeared in 25.6 percent of transactions

# a total of 2,159 transactions contained only a single item, while one transaction had 32 items
# first quartile and median purchase size are 2 and 3 items respectively

# look at the contents of a sparse matrix 
inspect(groceries[1:10])

# check the support level for the first five items in the grocery data
itemFrequency(groceries[, 1:5])

# the items in the sparse matrix are sorted in columns by alphabetical order

# set the minimum support at 10%
itemFrequencyPlot(groceries, support = 0.1)

# limit the plot to a specific number of items (e.g. 15 ones)
itemFrequencyPlot(groceries, topN = 15)

# visualize the sparse matrix for the first 5 items
image(groceries[1:5])

# 5 transactions and 169 possible items we requested
# cells in the matrix are filled with black for transactions (rows) where the item (column) was purchased

# it may help with the identification of potential data issues
# columns that are filled all the way down could indicate items that are purchased in every transaction

# patterns in the diagram may help reveal interesting segments of transactions or items, 
# particularly if the data is sorted in interesting ways
# e.g. if the transactions are sorted by date, patterns in the black dots could reveal 
# seasonal effects in the number or types of items people purchase

# this visualization could be especially powerful if the items were also sorted into categories
# it will not be as useful for extremely large transaction databases because the cells will be too small to discern

# random selection of 100 transactions
image(sample(groceries, 100))

# find the association rules using the apriori algorithm
# support at 0.6% (very low) and confidence at 25%, minimum length of a rule is 2 elements
groceryrules <- apriori(groceries, parameter = list(support = 0.006, confidence = 0.25, minlen = 2))

groceryrules

summary(groceryrules)

# look at specific rules
inspect(groceryrules[1:10])

# reorder the rules so that we are able to inspect the most meaningful ones
inspect(sort(groceryrules, by = "lift")[1:5])

inspect(sort(groceryrules, by = "confidence")[1:5])

inspect(sort(groceryrules, by = "support")[1:5])

inspect(sort(groceryrules, by = "count")[1:5])

# what drives people to buy root vegetables?
rules.rootveg<-apriori(data=groceries, parameter=list(supp=0.01,conf = 0.005), 
appearance=list(default="lhs", rhs="root vegetables"), control=list(verbose=F)) 
rules.rootveg.byconf<-sort(rules.rootveg, by="confidence", decreasing=TRUE)
inspect(head(rules.rootveg.byconf))

# on the opposite - what else will I buy if I added root vegetable to my basket?
rules.rootvegopp<-apriori(data=groceries, parameter=list(supp=0.01,conf = 0.005), 
appearance=list(default="rhs", lhs="root vegetables"), control=list(verbose=F)) 
rules.rootvegopp.byconf<-sort(rules.rootvegopp, by="confidence", decreasing=TRUE)
inspect(head(rules.rootvegopp.byconf))

# look at specific products
berryrules <- subset(groceryrules, items %in% "berries")
inspect(berryrules)

# some plots
install.packages("arulesViz")
library(arulesViz)

itemFrequencyPlot(groceries, topN=10, type="absolute", main="Item Frequency") 
itemFrequencyPlot(groceries, topN=10, type="relative", main="Item Frequency") 

plot(groceryrules)

plot(rules.rootveg)

plot(groceryrules, method="matrix", measure="lift")

plot(groceryrules, measure=c("support","lift"), shading="confidence")

plot(groceryrules, shading="order", control=list(main="Two-key plot"))

plot(groceryrules, method="grouped") 

plot(rules.rootveg, method="grouped") 

plot(groceryrules, method="graph")

plot(rules.rootveg, method="graph")

plot(groceryrules, method="paracoord", control=list(reorder=TRUE))

plot(rules.rootveg, method="paracoord", control=list(reorder=TRUE))

# using the ECLAT algorithm
freq.items<-eclat(groceries, parameter=list(supp=0.006, maxlen=15)) 
inspect(freq.items)

# basic statistics with reference to confidence
freq.rules<-ruleInduction(freq.items, groceries, confidence=0.5)
freq.rules

freq.items<-eclat(groceries, parameter=list(supp=0.05, maxlen=15)) 
inspect(freq.items)
freq.rules<-ruleInduction(freq.items, groceries, confidence=0.1)
freq.rules
inspect(freq.rules)

# saving the output 
write(groceryrules, file = "groceryrules.csv", sep = ",", quote = TRUE, row.names = FALSE)

# what happens if we take the output as a data frame?
groceryrules_df <- as(groceryrules, "data.frame")

str(groceryrules_df)
