pipeline {
    agent any
    
    tools {
        maven 'Maven-3.9.0'
        jdk 'OpenJDK-17'
    }
    
    environment {
        // Nexus and GitHub info
        NEXUS_VERSION = "nexus3"
        NEXUS_PROTOCOL = "http"
        NEXUS_URL = "localhost:8090"
        NEXUS_REPOSITORY = "maven-snapshots"
        NEXUS_CREDENTIAL_ID = "nexus-credentials"
        GITHUB_REPO = "https://github.com/suhaibmdv/jenkins_springboot_nexus.git"
        
        // POM details (manually entered to avoid security sandbox issues)
        ARTIFACT_ID = "hello-world-spring-boot"
        GROUP_ID = "com.example"
        VERSION = "1.0.0-SNAPSHOT"
        PACKAGING = "jar"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code from GitHub...'
                git branch: 'main', url: "${GITHUB_REPO}"
            }
        }

        stage('Build') {
            steps {
                echo 'Building the application...'
                sh 'mvn clean compile'
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'mvn test'
            }
            post {
                always {
                    junit testResults: 'target/surefire-reports/*.xml', allowEmptyResults: true
                }
            }
        }

        stage('Package') {
            steps {
                echo 'Packaging the application...'
                sh 'mvn package -DskipTests'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }

        stage('Deploy to Nexus') {
            steps {
                echo 'Deploying artifacts to Nexus...'
                script {
                    def repositoryName = VERSION.endsWith("SNAPSHOT") ? "maven-snapshots" : "maven-releases"
                    def artifactPath = "target/${ARTIFACT_ID}-${VERSION}.${PACKAGING}"

                    if (!fileExists(artifactPath)) {
                        error "Artifact file not found: ${artifactPath}"
                    }

                    nexusArtifactUploader(
                        nexusVersion: NEXUS_VERSION,
                        protocol: NEXUS_PROTOCOL,
                        nexusUrl: NEXUS_URL,
                        groupId: GROUP_ID,
                        version: VERSION,
                        repository: repositoryName,
                        credentialsId: NEXUS_CREDENTIAL_ID,
                        artifacts: [
                            [
                                artifactId: ARTIFACT_ID,
                                classifier: '',
                                file: artifactPath,
                                type: PACKAGING
                            ],
                            [
                                artifactId: ARTIFACT_ID,
                                classifier: '',
                                file: "pom.xml",
                                type: "pom"
                            ]
                        ]
                    )
                    echo "Artifact deployed successfully to Nexus"
                }
            }
        }

        stage('Integration Tests') {
            steps {
                echo 'Running integration tests...'
                sh 'mvn verify -DskipUTs'
            }
        }
    }

    post {
        always {
            echo 'Cleaning workspace...'
            cleanWs()
        }
        success {
            echo 'Pipeline executed successfully!'
            // Optional email notification
            /*
            emailext(
                subject: "SUCCESS: Job '${env.JOB_NAME} ${env.BUILD_NUMBER}'",
                body: "Good news! The build ${env.BUILD_URL} completed successfully.",
                to: "${env.CHANGE_AUTHOR_EMAIL}"
            )
            */
        }
        failure {
            echo 'Pipeline failed!'
            // Optional email notification
            /*
            emailext(
                subject: "FAILED: Job '${env.JOB_NAME} ${env.BUILD_NUMBER}'",
                body: "Build failed. Check console output at ${env.BUILD_URL}",
                to: "${env.CHANGE_AUTHOR_EMAIL}"
            )
            */
        }
    }
}
