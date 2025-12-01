# Setup Script for NFL Matchup Predictor
# Run this once to create necessary directories and install packages

# Create directory structure
create_project_structure <- function() {
  dirs <- c(
    "src/data",
    "src/data/predictions", 
    "src/data/performance"
  )
  
  for (dir in dirs) {
    if (!dir.exists(dir)) {
      dir.create(dir, recursive = TRUE)
      cat("Created directory:", dir, "\n")
    } else {
      cat("Directory already exists:", dir, "\n")
    }
  }
}

# Install required packages
required_packages <- c(
  "shiny",      # Web application framework
  "dplyr",      # Data manipulation
  "nflreadr",   # NFL data access
  "readr",      # CSV file reading/writing
  "lubridate"   # Date/time manipulation
)

install_packages <- function() {
  missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]
  
  if (length(missing_packages) > 0) {
    cat("Installing missing packages:", paste(missing_packages, collapse = ", "), "\n")
    install.packages(missing_packages)
    cat("Installation complete!\n")
  } else {
    cat("All required packages are already installed.\n")
  }
}

# Verify installations
verify_setup <- function() {
  cat("\nVerifying package installations:\n")
  for (pkg in required_packages) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      cat("✓", pkg, "- OK\n")
    } else {
      cat("✗", pkg, "- FAILED\n")
    }
  }
}

# Main setup function
main_setup <- function() {
  cat("Setting up NFL Matchup Predictor...\n\n")
  
  cat("1. Creating directory structure...\n")
  create_project_structure()
  
  cat("\n2. Installing required packages...\n")
  install_packages()
  
  cat("\n3. Verifying setup...\n")
  verify_setup()
  
  cat("\n✅ Setup complete! Run the app with: shiny::runApp('src')\n")
}

# Run setup if script is executed directly
if (interactive()) {
  main_setup()
} else {
  main_setup()
}
