# Use the official R base image
FROM r-base:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libsasl2-dev \
    libz-dev \
    pkg-config

# Install required R packages
RUN R -e "install.packages('shiny', repos='https://cran.rstudio.com/')"
RUN R -e "install.packages('shinyWidgets', repos='https://cran.rstudio.com/')"
RUN R -e "install.packages('dplyr', repos='https://cran.rstudio.com/')"
RUN R -e "install.packages('mongolite', repos='https://cran.rstudio.com/')"
RUN R -e "install.packages('randomForest', repos='https://cran.rstudio.com/')"
RUN R -e "install.packages('dotenv', repos='https://cran.rstudio.com/')"

# Copy your Shiny app files to the container
COPY . /app

# Set the working directory
WORKDIR /app

# Expose the Shiny app port
EXPOSE 3838

# Run the Shiny app
CMD ["R", "-e", "shiny::runApp('/app', host = '0.0.0.0', port = 3838)"]

