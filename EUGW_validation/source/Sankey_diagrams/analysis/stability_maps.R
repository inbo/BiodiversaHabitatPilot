# stability maps

# STABLEpx
# which pixels are stable in their classification label across all years
stable <- app(r_stack, fun = function(x) all(x == x[1])) # all values same??

# plot and save
plot(stable, main="Stable (TRUE) vs Changed (FALSE)")
writeRaster(stable, file = file.path(dir_out, "stable_pixels.tif"))
cat(paste0("DONE, map saved to ", file.path(dir_out, "stable_pixels.tif"), "\n"))

# NCHANGES
## number of classification switches per pixel across all years
nchanges <- app(r_stack, fun = function(x) sum(diff(x) != 0))

# plot and save
plot(nchanges, main = paste0("Number of changes (", min(as.integer(years)), " – ", max(as.integer(years)),")"))
writeRaster(nchanges, file = file.path(dir_out, "nchanges_per_pixel.tif"))
cat(paste0("DONE, map saved to ", file.path(dir_out, "nchanges_per_pixel.tif"), "\n"))
