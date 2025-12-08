## minimal required sample size --> binomial test ####
# Load required libraries
# chrome-extension://efaidnbmnnnibpcajpcglclefindmkaj/https://sites.calvin.edu/scofield/courses/m343/F15/handouts/binomialTestPower.pdf
#install.packages("binom")
library(binom)       # for binomial confidence intervals
library(nnet)        # for multinomial modeling
library(MASS)        # for chisq.test with simulated data
#install.packages("mosaic")
library(mosaic)

# Parameters
expected_accuracy <- 0.85        # Expected (or desired) accuracy per class
margin_error <- 0.05             # Desired margin of error
z_value <- qnorm(0.975)          # Z-score for 95% confidence (two-tailed)
N = 700                          # Total population      

# Function to calculate required sample size per class - infinite population
required_sample_size <- function(p, e, z) {
  n <- (z^2 * p * (1 - p)) / (e^2)
  return(ceiling(n))
}

# Function to calculate required sample size per class - infinite population
required_sample_size2 <- function(p, e, z) {
  n <- (z^2 * p * (1 - p)+e^2) / (e^2)
  return(ceiling(n))
}


# Function to calculate required sample size per class - finite (small) population
required_sample_size3 <- function(p, e, z , N) {
  n <- (z^2 * p * (1 - p)+e^2) / (e^2 + (z^2 * p * (1 - p)+e^2) / N)
  return(ceiling(n))
}


# Apply the function for expected accuracy
samples_per_class <- required_sample_size(expected_accuracy, margin_error, z_value)
samples_per_class2 <- required_sample_size2(expected_accuracy, margin_error, z_value)
samples_per_class3 <- required_sample_size3(expected_accuracy, margin_error, z_value, N)



# Output results
cat("Required samples per class:", samples_per_class, "\n")
cat("Required samples per class (more strict):", samples_per_class2, "\n")
cat("Required samples per class for finite population:", samples_per_class3, "\n")


# Let's check our assumptions with a real binomial test with sample size 200, nr. of successes = 170 (proportion of success is 0.85). What would be our 95% confidence interval of our proportion of succes?
170/200
binom.confint(x = 170, n = 200, conf.level = 0.95, methods = "wilson")  
binom.confint(x = 170, n = 200, conf.level = 0.95, methods = "all") # you see the proportion estimate (0.85) and the confidence interval +/- [p - e ; p + e] with e the marginal error rate.


# If you have different "required" user accuracy among your classes, you can calculate the minimal sample sizes as follow: 
expected <- c(0.5, 0.6, 0.7, 0.8, 0.9) 
minimal_samples_per_class <- sapply(expected, required_sample_size, e = margin_error, z = z_value)


## Power analysis of binomial test ####

qbinom(0.025,200,0.85) # 0.025 = alpha (0.05) / 2
pbinom(160,200,0.85)
pbinom(159,200,0.85)


plotDist("binom", params=c(200, .85), col=c("red","forestgreen"), groups=abs(x-170) <= 10) # you see are "accepted region for the producer accuracy is between 160 - 180 of the 200 samples, which 0.8 - 0.9 UA. Medium estimate is 0.85

# Computing β, the probability of Type II Error

# Suppose our UA of a stratum on the map in our AOI has a probability of 0.95. Then, counter to what is hypothesized in H0, X ∼ Binom(200,0.95). We overlay this distribution (displayed in gray) with the null distribution.

plotDist("binom", params=c(200, .85), col=c("red","forestgreen"), groups=abs(x-170) <= 10, xlim=c(150,200), ylim=c(0,0.15)) 
plotDist("binom", params=c(200, .95), col="gray60", add=TRUE)

#The probability of making a Type II error, β, should be small, as the likelihood of values from our UA (with # πa =0.95) falling in the green region (where the null hypothesis is not rejected) appears to be small. We can # find its actual value with commands like
sum(dbinom(160:180, 200, 0.95)) 
# or
pbinom(180, 200, .95) - pbinom(159, 200, .95)

# And the Type II error, β, for πa = 0.75
plotDist("binom", params=c(200, .85), col=c("red","forestgreen"), groups=abs(x-170) <= 10, xlim=c(130,190), ylim=c(0,0.1)) 
plotDist("binom", params=c(200, .75), col="gray60", add=TRUE)

sum(dbinom(160:180, 200, 0.75)) 
# or
pbinom(180, 200, .75) - pbinom(159, 200, .75)


piAlt = seq(0, 1, .02) 
myBeta = pbinom(180, 200, piAlt) - pbinom(159, 200, piAlt) 
plot(piAlt, 1 - myBeta, type = "l",
     xlab = "Probability of Success",
     ylab = "Power",
     main = "Power Curve for Binomial Test")
abline(h = 0.8, col = "red", lty = 2, lwd = 2)


plot(piAlt, 1 - myBeta, type = "l",
     xlab = "Probability of Success",
     ylab = "Power",
     main = "Power Curve for Binomial Test",xlim=c(0.7,1))
abline(h = 0.8, col = "red", lty = 2, lwd = 2)




# Power plot for the number of samples
# Define range of sample sizes
enn <- 1:500

# Initialize power vector
power <- numeric(length(enn))

# Loop over sample sizes
for (i in seq_along(enn)) {
  n <- enn[i]
  
  # Critical value under null hypothesis p0 = 0.85
  # For two-tailed test at alpha = 0.05, split alpha in both tails (0.025)
  crit_low <- qbinom(0.025, n, 0.85)
  crit_high <- qbinom(0.975, n, 0.85)
  
  # Calculate beta under alternative hypothesis p1 = 0.75
  # i.e., probability test fails to reject H0 when H1 is true
  beta <- pbinom(crit_high, n, 0.75) - pbinom(crit_low - 1, n, 0.75)
  
  # Power = 1 - beta
  power[i] <- 1 - beta
}

# Plot using base R
plot(enn, power, type="l", lwd=1, xlab="Sample size (n)", ylab="Power", col="blue", main="Power Curve for Binomial Test")



## One-sided hypothesis testing and power analysis #####
# Load required package
if (!require(pwr)) {
  install.packages("pwr")
  library(pwr)
}

# Set parameters
p0 <- 0.85       # Null hypothesis proportion
p1 <- 0.75       # Alternative hypothesis proportion (smaller than p0)
alpha <- 0.05    # Significance level
n_range <- 10:500  # Range of sample sizes to evaluate

# Function to compute power for each sample size
compute_power <- function(n, p0, p1, alpha) {
  x_crit <- qbinom(alpha, size = n, prob = p0)  # critical value for rejection region
  power <- pbinom(x_crit, size = n, prob = p1)  # power = P(X <= x_crit | p1)
  return(power)
}

# Vector to store power values
powers <- sapply(n_range, compute_power, p0 = p0, p1 = p1, alpha = alpha)

# Plot power vs. sample size
plot(n_range, powers,
     type = "l", lwd = 2, col = "blue",
     xlab = "Sample Size (n)",
     ylab = "Power",
     main = paste("Power Analysis for Binomial Test\nH0: p =", p0, "vs H1: p <", p0))
abline(h = 0.8, col = "red", lty = 2)  # Common target power line
text(100, 0.82, "Target Power = 0.8", col = "red", pos = 3)



# === MULTINOMIAL TEST (overall class proportions) ===
# Let's assume we have 3 classes, with this confusion matrix reference totals
classified_counts <- c(80, 90, 30)   # predicted class counts
reference_totals <- c(85, 95, 20)    # ground truth counts

# Chi-square test to compare distributions
chi_test <- chisq.test(x = classified_counts, p = reference_totals / sum(reference_totals))


cat("\nMultinomial (All Classes):\n")
print(chi_test)
