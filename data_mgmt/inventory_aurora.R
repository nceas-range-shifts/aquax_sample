fs <- list.files('/home/shares/data-aquax/SDM', pattern = '.parquet')
df <- data.frame(f = fs)
write.csv(df, here::here('data_mgmt/inventory_aurora.csv'))



