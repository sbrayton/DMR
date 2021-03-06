## ===============================================
## The Box Plot Rule workflow
## ===============================================
BPrule.wf <- function(form,train,test,...) {
    require(dplyr, quietly=TRUE)
    ms <- as.matrix(filter(train,Insp != 'fraud') %>%
                         group_by(Prod) %>%
                         summarise(median=median(Uprice),iqr=IQR(Uprice)) %>%
                         select(median,iqr))
    rownames(ms) <- levels(train$Prod)
    ms[which(ms[,'iqr']==0),'iqr'] <- ms[which(ms[,'iqr']==0),'median']
    ORscore <- abs(test$Uprice-ms[test$Prod,'median']) /
               ms[test$Prod,'iqr']
    rankOrder <- order(ORscore,decreasing=T)
    res <- list(testSet=test,rankOrder=rankOrder,
                probs=matrix(c(ORscore,ifelse(test$Insp=='fraud',1,0)),ncol=2))
    res
}

myBPrule.wf <- function(form,train,test,...) {
  require(dplyr, quietly=TRUE)
  ms <- as.matrix(filter(train,Insp != 'fraud') %>%
                    group_by(Prod) %>%
                    summarise(median=mean(Uprice),iqr=sd(Uprice)) %>%
                    select(median,iqr))
  rownames(ms) <- levels(train$Prod)
  ms[which(ms[,'iqr']==0),'iqr'] <- ms[which(ms[,'iqr']==0),'median']
  ORscore <- abs(test$Uprice-ms[test$Prod,'median']) /
    ms[test$Prod,'iqr']
  rankOrder <- order(ORscore,decreasing=T)
  res <- list(testSet=test,rankOrder=rankOrder,
              probs=matrix(c(ORscore,ifelse(test$Insp=='fraud',1,0)),ncol=2))
  res
}


## ===============================================
## The LOF workflow
## ===============================================
LOF.wf <- function(form, train, test, k, ...) {
  require(DMwR2, quietly=TRUE)
  ntr <- nrow(train)
  all <- as.data.frame(rbind(train,test))
  N <- nrow(all)
  ups <- split(all$Uprice,all$Prod)
  r <- list(length=ups)
  for(u in seq(along=ups)) 
    r[[u]] <- if (NROW(ups[[u]]) > 3) 
      lofactor(ups[[u]],min(k,NROW(ups[[u]]) %/% 2)) 
  else if (NROW(ups[[u]])) rep(0,NROW(ups[[u]])) 
  else NULL
  all$lof <- vector(length=N)
  split(all$lof,all$Prod) <- r
  all$lof[which(!(is.infinite(all$lof) | is.nan(all$lof)))] <- 
    SoftMax(all$lof[which(!(is.infinite(all$lof) | is.nan(all$lof)))])

  res <- list(testSet=test,
              rankOrder=order(all[(ntr+1):N,'lof'],decreasing=T),
              probs=as.matrix(cbind(all[(ntr+1):N,'lof'],
                                    ifelse(test$Insp=='fraud',1,0))))
  res
}

## ===============================================
## The NB with Smote workflow
## ===============================================
NBsm.wf <- function(form,train,test,C.perc="balance",dist="HEOM",...) {
    require(e1071,quietly=TRUE)
    require(UBL,quietly=TRUE)

    sup <- which(train$Insp != 'unkn')
    data <- as.data.frame(train[sup,c('ID','Prod','Uprice','Insp')])
    data$Insp <- factor(data$Insp,levels=c('ok','fraud'))
    newData <- SmoteClassif(Insp ~ .,data,C.perc=C.perc,dist=dist,...)
    model <- naiveBayes(Insp ~ .,newData)
    preds <- predict(model,test[,c('ID','Prod','Uprice','Insp')],type='raw')
    rankOrder <- order(preds[,'fraud'],decreasing=T)
    rankScore <- preds[,'fraud']
    
    res <- list(testSet=test,
              rankOrder=rankOrder,
              probs=as.matrix(cbind(rankScore,
                                    ifelse(test$Insp=='fraud',1,0))))
    res
}



## ===============================================
## The AdaBoosting workflow
## ===============================================

ab.wf <- function(form,train,test,ntrees=100,...) {
    require(RWeka,quietly=TRUE)
    sup <- which(train$Insp != 'unkn')
    data <- as.data.frame(train[sup,c('ID','Prod','Uprice','Insp')])
    data$Insp <- factor(data$Insp,levels=c('ok','fraud'))
    model <- AdaBoostM1(Insp ~ .,data,
                        control=Weka_control(I=ntrees))
    preds <- predict(model,test[,c('ID','Prod','Uprice','Insp')],
                     type='probability')
    rankOrder <- order(preds[,"fraud"],decreasing=TRUE)
    rankScore <- preds[,"fraud"]
    res <- list(testSet=test,
                rankOrder=rankOrder,
                probs=as.matrix(cbind(rankScore,
                                      ifelse(test$Insp=='fraud',1,0))))
    res
}


## ===============================================
## The AdaBoosting with Self-training workflow
## ===============================================

pred.ada <- function(m,d) {
    p <- predict(m,d,type='probability')
    data.frame(cl=colnames(p)[apply(p,1,which.max)],
               p=apply(p,1,max)
               )
}

ab.st.wf <- function(form,train,test,ntrees=100,...) {
    require(RWeka,quietly=TRUE)
    require(DMwR2,quietly=TRUE)
    train <- as.data.frame(train[,c('ID','Prod','Uprice','Insp')])
    train[which(train$Insp == 'unkn'),'Insp'] <- NA
    train$Insp <- factor(train$Insp,levels=c('ok','fraud'))
    model <- SelfTrain(form,train,
                       learner='AdaBoostM1',
                       learner.pars=list(control=Weka_control(I=ntrees)),
                       pred='pred.ada')
    preds <- predict(model,test[,c('ID','Prod','Uprice','Insp')],
                     type='probability')

    rankOrder <- order(preds[,'fraud'],decreasing=T)
    rankScore <- preds[,"fraud"]
    
    res <- list(testSet=test,
              rankOrder=rankOrder,
              probs=as.matrix(cbind(rankScore,
                                    ifelse(test$Insp=='fraud',1,0))))
    res
}
