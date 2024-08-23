library(shiny)
library(shinyWidgets)
library(dplyr)
library(mongolite)
library(randomForest)



# MongoDB Connection
mongo_conn <- mongo(
  collection = 'hr',
  url = Sys.getenv("MONGO_URL")
)

# Load Data from MongoDB
data <- mongo_conn$find()

# Shiny UI
ui <- fluidPage(
  # Custom CSS for styling
  tags$head(
    tags$style(HTML("
      #decision {
        font-size: 24px;
        font-weight: bold;
      }
      .recommended {
        color: green;
      }
      .not-recommended {
        color: red;
      }
      #recap {
        background-color: #f8f9fa;
        padding: 15px;
        border-radius: 10px;
        border: 1px solid #dee2e6;
        margin-top: 20px;
      }
      #recap h4 {
        font-weight: bold;
        margin-bottom: 10px;
      }
      #recap p {
        margin: 5px 0;
      }
    "))
  ),
  
  titlePanel("HR Hiring Decision Tool"),
  
  sidebarLayout(
    sidebarPanel(
      textInput("name", "Name", placeholder = "Joe Doe"),
      numericInput("age", "Age", value = NULL),
      selectInput("gender", "Gender", choices = c("Male" = 1, "Female" = 2)),
      selectInput("education", "Education Level", choices = c("Bachelor's" = 1, "Master's" = 2, "PhD" = 3)),
      numericInput("experience", "Years of Experience", value = NULL),
      numericInput("prev_companies", "Previous Companies Worked At", value = NULL),
      numericInput("distance", "Distance from Company (Miles)", value = NULL),
      sliderInput("interview_score", "Interview Score", min = 0, max = 100, value = 35),
      sliderInput("skill_score", "Skill Score", min = 0, max = 100, value = 68),
      sliderInput("personality_score", "Personality Score", min = 0, max = 100, value = 80),
      selectInput("recruitment_strategy", "Recruitment Strategy", 
                  choices = c("Aggressive" = 1, "Moderate" = 2, "Conservative" = 3)),
      actionButton("submit", "Submit", class = "btn-primary")
    ),
    
    mainPanel(
      progressBar(id = "progress", value = 0, display_pct = TRUE),
      uiOutput("decision"),
      uiOutput("recap")
    )
  )
)

# Shiny Server
server <- function(input, output, session) {
  
  observeEvent(input$submit, {
    # Update Progress Bar
    updateProgressBar(session, id = "progress", value = 20)
    
    # Capture user inputs
    new_data <- data.frame(
      name = input$name,
      Age = input$age,
      Gender = as.numeric(input$gender),
      EducationLevel = as.numeric(input$education),
      ExperienceYears = input$experience,
      PreviousCompanies = input$prev_companies,
      DistanceFromCompany = input$distance,
      InterviewScore = input$interview_score,
      SkillScore = input$skill_score,
      PersonalityScore = input$personality_score,
      RecruitmentStrategy = as.numeric(input$recruitment_strategy)
    )
    
    # Preprocess data
    name <- new_data$name
    new_data <- new_data %>%
      select(-name)
    
    updateProgressBar(session, id = "progress", value = 50)
    
    data <- data %>%
      select(-one_of("element_id"))
    
    # Handle Missing Values
    data <- data %>%
      na.omit()  # Removes rows with any NA values
    
    # Check if `new_data` has any missing values
    if (anyNA(new_data)) {
      showNotification("Missing values in the input data. Please ensure all fields are filled.", type = "error")
      return(NULL)
    }
    
    # Machine Learning Prediction
    rfmodel <- randomForest(HiringDecision ~ ., data = data, ntree = 505)
    
    prediction <- predict(rfmodel, new_data)
    
    prediction <- ifelse(prediction > 0.5, 1, 0)
    
    updateProgressBar(session, id = "progress", value = 80)
    
    new_data <- new_data %>%
      mutate(
        HiringDecision = prediction
      )
    
    # Insert new data into MongoDB
    mongo_conn$insert(new_data)
    
    new_data <- new_data %>%
      mutate(name = name)
    
    # Generate Hiring Decision
    decision_text <- ifelse(new_data$HiringDecision == 1, 
                            "Highly Recommended: We suggest proceeding with the hire", 
                            "Not Recommended: Consider other candidates")
    
    decision_class <- ifelse(new_data$HiringDecision == 1, 
                             "recommended", 
                             "not-recommended")
    
    output$decision <- renderUI({
      tags$div(class = paste("decision", decision_class), decision_text)
    })
    
    # Display Recap of Candidate's Information
    output$recap <- renderUI({
      tags$div(id = "recap",
               tags$h4("Candidate Information Recap"),
               tags$p("Name: ", tools::toTitleCase(input$name)),
               tags$p("Age: ", input$age),
               tags$p("Gender: ", ifelse(input$gender == 1, "Male", "Female")),
               tags$p("Education Level: ", switch(as.character(input$education), 
                                                  "1" = "Bachelor's", 
                                                  "2" = "Master's", 
                                                  "3" = "PhD")),
               tags$p("Years of Experience: ", input$experience),
               tags$p("Previous Companies: ", input$prev_companies),
               tags$p("Distance from Company: ", input$distance, " Miles"),
               tags$p("Interview Score: ", input$interview_score),
               tags$p("Skill Score: ", input$skill_score),
               tags$p("Personality Score: ", input$personality_score),
               tags$p("Recruitment Strategy: ", switch(as.character(input$recruitment_strategy), 
                                                       "1" = "Aggressive", 
                                                       "2" = "Moderate", 
                                                       "3" = "Conservative"))
      )
    })
    
    updateProgressBar(session, id = "progress", value = 100)
  })
}

# Run the Shiny app
shinyApp(ui = ui, server = server)
