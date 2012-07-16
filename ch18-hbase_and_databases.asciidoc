# Chapter 18: HBase and Databases


Region splitting and hot potatoes

Writing sorted data is even worse: you pick on one poor regionserver who loads up till she is ready to split; the still picking on it while trying to replicate

## tuning

### caching

### MSlab, jvm

Use it
Try not to tune it