# association rules
###
###
###

# based on the example by Prof. Katarzyna Kopczewska

#On-line materials
#http://mhahsler.github.io/arules/  - summary of arules:: package
#https://www.r-bloggers.com/examples-and-resources-on-association-rule-mining-with-r/  - overview of methods
#http://michael.hahsler.net/research/arules_RUG_2015/demo/  - demo by the Author

#Example student works:
#https://rpubs.com/airam/usl_p3 - in Polish, with interactive solutions
#https://rpubs.com/kkrynska/AssociationRules – in English, with interactive solutions
#https://rpubs.com/esobolewska/chords - in English, for music chords analysis
#https://rpubs.com/honkalimonka/UL3 - in English, with extra graphics
#https://kmatusz.github.io/USL/recommender.html - in English, prediction model with words cloud

# some essential packages
#arules: 	arules base package with data structures, mining algorithms (APRIORI and ECLAT), interest measures.
#arulesViz: 		Visualization of association rules.
#arulesCBA: 	Classification algorithms based on association rules (includes CBA).
#arulesSequences: 	Mining frequent sequences (cSPADE).

# reading the packages
install.packages("arules")
install.packages("arulesViz")
install.packages("arulesCBA")

library(arules)
library(arulesViz)
library(arulesCBA)

# read the data
trans1<-read.transactions("trans1.csv", format="basket", sep=",", skip=0)
trans1

inspect(trans1)

size(trans1) 

length(trans1)

LIST(head(trans1))

trans2<-read.transactions("trans2.csv", format="single", sep=";", cols=c("TRANS","ITEM"), header=TRUE)
trans2

inspect(trans2)

size(trans2) 

LIST(head(trans2))

# basic descriptive stats
round(itemFrequency(trans1),3)

itemFrequency(trans1, type="absolute")

ctab<-crossTable(trans1, sort=TRUE) 
ctab<-crossTable(trans1, measure="count", sort=TRUE) 
ctab

stab<-crossTable(trans1, measure="support", sort=TRUE)
round(stab, 3)

ptab<-crossTable(trans1, measure="probability", sort=TRUE) # jak support
round(ptab,3)

ltab<-crossTable(trans1, measure="lift", sort=TRUE)
round(ltab,2)

# co-occurence test (independence test)
# p-value of test in a table, H0:independent columns and rows
chi2tab<-crossTable(trans1, measure="chiSquared", sort=TRUE)
round(chi2tab,2)

# Eclat & Apriori
#The Eclat algorithm does not create rules - it digs through frequent sets to limit the data set. 
#It works by using eclat(). As a result, we obtain frequent sets and measure values determined for them (e.g. support).
#When specifying search restrictions, the minimum support for the set is usually specified (e.g. supp = 0.1). 
#One can also limit the maximum length of the set (e.g. to 10 elements maxlen=10). 
#To create rules, use the ruleInduction() function. Displaying sets and rules is with the inspect() command.

freq.items<-eclat(trans1, parameter=list(supp=0.25, maxlen=15))

inspect(freq.items)

round(support(items(freq.items), trans1) , 2) # vector of support values

# obtaining the rules
freq.rules<-ruleInduction(freq.items, trans1, confidence=0.9) 
freq.rules

inspect(freq.rules) # screening the rules

#The apriori algorithm creates frequent itemsets and based on these created itemsets it creates rules. 
#Default minimum values: minimum support (supp = 0.1), minimum confidence (conf = 0.8).

# creating the rules - standard settings
rules.trans1<-apriori(trans1, parameter=list(supp=0.1, conf=0.5))  

# sorting rules by confidence + displaying
rules.by.conf<-sort(rules.trans1, by="confidence", decreasing=TRUE)
inspect(head(rules.by.conf))

rules.by.lift<-sort(rules.trans1, by="lift", decreasing=TRUE) # sorting by lift
inspect(head(rules.by.lift))

rules.by.count<- sort(rules.trans1, by="count", decreasing=TRUE) # sorting by count
inspect(head(rules.by.count))

rules.by.supp<-sort(rules.trans1, by="support", decreasing=TRUE) 
inspect(head(rules.by.supp))

# digging the rules
#1. in the context of induction - what is the cause / consequence of a given purchase
#2. looking for rules for closed itemsets
#3. finding significant rules
#4. looking for maximal rules
#5. looking for redundant rules
#6. searching subsets and supersets
#7. by searching for transactions that support the rules

#ad1
# generating rules
rules.banana<-apriori(data=trans1, parameter=list(supp=0.001,conf = 0.08), 
appearance=list(default="lhs", rhs="banana"), control=list(verbose=F)) 

# sorting and displaying the rules
rules.banana.byconf<-sort(rules.banana, by="confidence", decreasing=TRUE)
inspect(head(rules.banana.byconf))

rules.banana<-apriori(data=trans1, parameter=list(supp=0.001,conf = 0.08), 
appearance=list(default="rhs",lhs="banana"), control=list(verbose=F)) 

rules.banana.byconf<-sort(rules.banana, by="confidence", decreasing=TRUE)
inspect(head(rules.banana.byconf))

#ad2 (closed itemsets)
#A closed set is one where the superset has lower support than that set.
#A closed frequent set is one that is closed and its support is not less than a fixed value (minsup).
#More at: http://www.hypertextbookshop.com/dataminingbook/public_version/contents/chapters/chapter002/section004/blue/page002.html 

#Closed transactions with the apriori() and eclat() command 
#- the apriori algorithm allows you to search for rules for closed frequent itemsets 
#- the options should be set: parameter=list(target="closed frequent itemsets") 
#or parameter=list(target="maximally frequent itemsets") - closed transactions are the most complex and common 
#- incorrectly set rule parameters may cause the set of closed rules to be empty.

trans1.closed<-apriori(trans1, parameter=list(target="closed frequent itemsets", support=0.25))

inspect(trans1.closed)

class(trans1.closed) 

is.closed(trans1.closed)  

freq.closed<-eclat(trans1, parameter=list(supp=0.15, maxlen=15, target="closed frequent itemsets"))

inspect(freq.closed)

is.closed(freq.closed)

freq.max<-eclat(trans1, parameter=list(supp=0.15, maxlen=15, target="maximally frequent itemsets"))

inspect(freq.max) # not clear output, ham is not more frequent than individual baskets

#ad3 (significant rules)
#Significance of rules is tested with Fisher’s exact test and is corrected due to multi-comparisons
#About Fisher test: https://en.wikipedia.org/wiki/Fisher%27s_exact_test 
#About correction adjust=“bonferroni” https://en.wikipedia.org/wiki/Bonferroni_correction 
#About correction adjust=“holm” https://en.wikipedia.org/wiki/Holm%E2%80%93Bonferroni_method 
#About correction adjust=“fdr” https://en.wikipedia.org/wiki/False_discovery_rate 

is.significant(rules.banana, trans1)    

#ad4 (maximal rules)
#Set is maximal if it does not contain a superset

is.maximal(rules.banana) 

inspect(rules.banana[is.maximal(rules.banana)==TRUE]) 

#ad5 (redundant rules)
#The rule is redundant if there is a more general one with the same or higher confidence value.

is.redundant(rules.banana)

inspect(rules.banana[is.redundant(rules.banana)==FALSE])

#ad6 (supersets and subsets)
#A subset is a set that is contained within another (existing) set.
#A superset is a set that is not contained in another (existing) set.

is.superset(rules.banana) 

is.subset(rules.banana)

is.superset(rules.banana, sparse=FALSE) 

#ad7 (transactions with rules)

#A mechanism that displays the transactions (transaction IDs) for which a given set was purchased (one that meets certain rules).

supportingTransactions(rules.banana, trans1)

inspect(supportingTransactions(rules.banana, trans1))

# similarity and dissimilarity measures

#The Jaccard Index can be derived from the dissimilarity() function in the arules :: package. It can be designated for sets or transactions.
#The starting point is always the same: for sets / transactions A and B it is counted how many times it occurs:
#- A and B; A but not B; B but not A; neither A nor B;
#- general A in all sets / transactions
#- generally B in all sets / transactions

#Jaccard Index is the number in both sets / the number in one of the sets
#The formal Jaccard index notation J (X, Y) = | X∩Y | / | XUY | -> similarity
#Alternative notation is Jaccard distance = 1-Jaccard coefficient -> dissimilarity

#J index = 100% 	| distance J = 0 		- when all products are in X and Y
#J index = 50% 	| distance J = 0.5 	- when every second product is shared in X and Y
#J index = 0% 	| distance J = 1 		- when all products in X and Y are different

trans.sel<-trans1[,itemFrequency(trans1)>0.05] # selected transations
d.jac.i<-dissimilarity(trans.sel, which="items") # Jaccard as default
round(d.jac.i,2) 

#interpretation: orange & ham J=0.71 – are very different (in 71% they do not overlap)
#J_coef=f11/(f+1 + f1+ -f11)=2/(3+6-2)=0.29  so J_dist=1-0.29=0.71

trans.sel<-trans1[,itemFrequency(trans1)>0.05] # selected transactions

# Jaccard by default
d_jac.t<-dissimilarity(trans.sel, which="transactions") 
round(d_jac.t,2) 

#interpretation: transactions 6 & 1 J=0.25 –> they are very similar (in 25% they do not overlap). 
#This is true: trans6={apple,coke,orange} & trans1={apple,banana,coke,orange}.
#Only one of four elements (25%) is different/missing.

plot(hclust(d_jac.t, method="ward.D2"), main="Dendrogram for trans")
plot(hclust(d.jac.i, method="ward.D2"), main="Dendrogram for items")

# visualization
itemFrequencyPlot(trans1, topN=10, type="absolute", main="Item Frequency") 
itemFrequencyPlot(trans1, topN=10, type="relative", main="Item Frequency") 

image(trans1)
plot(rules.trans1, method="matrix", measure="lift")

plot(rules.trans1) 
plot(rules.trans1, measure=c("support","lift"), shading="confidence")

plot(rules.trans1, method="grouped") 
plot(rules.trans1, method="graph", control=list(type="items"))

plot(rules.trans1, method="paracoord", control=list(reorder=TRUE))
plot(rules.trans1, shading="order", control=list(main="Two-key plot"))

#hierarchical rules - refer to some broader categories
names(itemFrequency(trans1)) # info on product categories

names.real<-c("apple", "banana", "bread", "butter", "cheese", "coke", "ham",    "orange") # old names

names.level1<-c("fruits", "fruits", "breakfast", "breakfast", "breakfast", "drink", "breakfast", "fruits") # new names

# recoding the categories
itemInfo(trans1)<-data.frame(labels = names.real, level1 = names.level1)
itemInfo(trans1)

trans1_level2<-aggregate(trans1, by="level1")
trans1

inspect(trans1) # transactions with old names

inspect(trans1_level2) # transactions with new names

itemInfo(trans1_level2) ## labels sorted alphabetically

# The following analysis of the rules at a higher level of aggregation shows that it is easier to draw conclusions about purchasing patterns.

rules.trans1_lev2<-apriori(trans1_level2, parameter=list(supp=0.1, conf=0.5)) 

rules.by.conf<-sort(rules.trans1_lev2, by="confidence", decreasing=TRUE) 
inspect(head(rules.by.conf))

# random transactions
trans<-random.transactions(nItems=10, nTrans=15, method="independent", verbose=FALSE)
image(trans)

inspect(trans)

# Based on the drawn data, you can create rules (apriori()) and view them (inspect(), sort()), check their length (size()) and how many were created (legnth()), create data sets (eclat())

rules.random<-apriori(trans, parameter=list(supp=0.05, conf=0.3)) 
inspect(rules.random)
rules.by.conf<-sort(rules.random, by="confidence", decreasing=TRUE) 
inspect(rules.by.conf)
size(rules.by.conf)
length(rules.by.conf)
freq.items<-eclat(trans, parameter=list(supp=0.25, maxlen=15)) # basic eclat
inspect(freq.items)
