pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds-id') // Replace with your Jenkins credentials ID
        IMAGE_NAME = 'villeog/my-app'
        TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                docker build -t $IMAGE_NAME:$TAG .
                docker tag $IMAGE_NAME:$TAG $IMAGE_NAME:latest
                '''
            }
        }

        stage('Push to DockerHub') {
            steps {
                sh '''
                echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                docker push $IMAGE_NAME:$TAG
                docker push $IMAGE_NAME:latest
                '''
            }
        }

        stage('Verify kubectl context') {
            steps {
                sh 'kubectl config current-context'
                sh 'kubectl get nodes'
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                sed -i "s|image:.*|image: $IMAGE_NAME:$TAG|" k8s/deployment.yaml
                kubectl apply -f k8s/deployment.yaml
                kubectl rollout status deployment/my-app-deployment
                '''
            }
        }

        stage('Deploy Ingress') {
            steps {
                sh 'kubectl apply -f k8s/ingress.yaml'
                sh 'kubectl get ingress'
            }
        }

        stage('Smoke Test') {
            steps {
                sh 'curl -s http://<your-ingress-ip>/your-path || echo "App not reachable"'
            }
        }
    }

    post {
        always {
            sh 'docker image prune -f'
        }
        success {
            echo "✅ Deployment successful: http://<your-ingress-ip>/your-path"
        }
        failure {
            echo "❌ Deployment failed. Check logs above."
        }
    }
}

