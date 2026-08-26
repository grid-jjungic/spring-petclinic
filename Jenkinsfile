pipeline {
    agent {
        label 'docker-agent'
    }

    environment {
        DOCKER_CREDS_ID = 'docker-hub-credentials'
        // DOCKER_USER is read from jenkins global environment variables
    }

    stages {
        stage('Initialize Metadata') {
            steps {
                script {
                    // Extract short Git commit hash across all pipeline stages
                    env.SHORT_COMMIT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()

                    echo "Target Docker User: ${env.DOCKER_USER}"
                    echo "Executing build for Commit: ${env.SHORT_COMMIT}"
                }
            }
        }

        // Merge request pipeline
        stage('Merge Request Pipeline') {
            when {
                changeRequest()
            }
            stages {
                stage('Checkstyle') {
                    steps {
                        sh './mvnw checkstyle:checkstyle'
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'target/checkstyle-result.xml', allowEmptyArchive: true
                        }
                    }
                }

                stage('Test') {
                    steps {
                        sh './mvnw test'
                    }
                    post {
                        always {
                            junit allowEmptyResults: true, testResults: 'target/surefire-reports/*.xml'
                        }
                    }
                }

                stage('Build App') {
                    steps {
                        sh './mvnw package -DskipTests'
                    }
                }

                stage('Create & Push MR Docker Image') {
                    steps {
                        script {
                            docker.withRegistry('https://index.docker.io/v1/', "${DOCKER_CREDS_ID}") {
                                def mrImage = docker.build("${env.DOCKER_USER}/mr:${env.SHORT_COMMIT}", ".")
                                mrImage.push()
                            }
                        }
                    }
                }
            }
        }

        // Main branch pipeline (docker-1-task)
        stage('Main Branch Pipeline') {
            when {
                branch 'docker-1-task'
            }
            stages {
                stage('Build App Package') {
                    steps {
                        sh './mvnw package -DskipTests'
                    }
                }

                stage('Create & Push Main Docker Image') {
                    steps {
                        script {
                            docker.withRegistry('https://index.docker.io/v1/', "${DOCKER_CREDS_ID}") {
                                def mainImage = docker.build("${env.DOCKER_USER}/main:${env.SHORT_COMMIT}", ".")
                                mainImage.push("${env.SHORT_COMMIT}")
                                mainImage.push("latest")
                            }
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
