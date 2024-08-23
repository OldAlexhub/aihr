# Use the official R base image with R version 4.4.1
FROM r-base:4.4.1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libsodium-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages from CRAN
RUN R -e "install.packages(c('shiny', 'shinyWidgets', 'dplyr', 'mongolite', 'randomForest', 'dotenv'), repos='https://cloud.r-project.org/')"

# Create and set the working directory
WORKDIR /app

# Copy the Shiny app files to the Docker image
COPY . /app

# Expose the port on which the Shiny app will run
EXPOSE 3838

# Run the Shiny app
CMD ["R", "-e", "shiny::runApp('/app', host = '0.0.0.0', port = 3838)"]

