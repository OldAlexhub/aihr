# Use the official R image
FROM r-base:latest

# Install dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && R -e "install.packages(c('shiny', 'shinyWidgets', 'dplyr', 'mongolite', 'randomForest', 'dotenv'))"

# Copy your Shiny app files to the container
COPY . /app

# Set the working directory
WORKDIR /app

# Expose the Shiny app port
EXPOSE 3838

# Run the Shiny app
CMD ["R", "-e", "shiny::runApp('/app', host = '0.0.0.0', port = 3838)"]
