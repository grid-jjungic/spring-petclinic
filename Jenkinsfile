pipeline {
    agent {
        label 'docker-agent'
    }

    environment {
        DOCKER_CREDS_ID = 'docker-hub-creds'
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
                        withCredentials([usernamePassword(
                            credentialsId: env.DOCKER_CREDS_ID,
                            usernameVariable: 'DOCKER_HUB_USER',
                            passwordVariable: 'DOCKER_HUB_PAT'
                        )]) {
                            sh 'export DOCKER_CLIENT_TIMEOUT=120'
                            sh 'export COMPOSE_HTTP_TIMEOUT=120'
                            sh 'echo "$DOCKER_HUB_PAT" | docker login -u "$DOCKER_HUB_USER" --password-stdin'
                            sh 'docker build -t "$DOCKER_USER/mr:$SHORT_COMMIT" .'
                            sh 'docker push "$DOCKER_USER/mr:$SHORT_COMMIT"'
                            sh 'docker logout'
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
                        withCredentials([usernamePassword(
                            credentialsId: env.DOCKER_CREDS_ID,
                            usernameVariable: 'DOCKER_HUB_USER',
                            passwordVariable: 'DOCKER_HUB_PAT'
                        )]) {
                            sh 'export DOCKER_CLIENT_TIMEOUT=120'
                            sh 'export COMPOSE_HTTP_TIMEOUT=120'
                            sh 'echo "$DOCKER_HUB_PAT" | docker login -u "$DOCKER_HUB_USER" --password-stdin'
                            sh 'docker build -t "$DOCKER_USER/main:$SHORT_COMMIT" -t "$DOCKER_USER/main:latest" .'
                            sh 'docker push "$DOCKER_USER/main:$SHORT_COMMIT"'
                            sh 'docker push "$DOCKER_USER/main:latest"'
                            sh 'docker logout'
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
