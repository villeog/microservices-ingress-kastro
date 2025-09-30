pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('villers118') // Jenkins credentials ID
        IMAGE_NAME = 'villeog/my-app'
        TAG = "${env.BUILD_NUMBER}"
        KUBECONFIG = '/var/lib/jenkins/.kube/config' // Local kubeconfig path
        DEPLOYMENT_NAME = 'my-app-deployment'
        SERVICE_NAME = 'my-app-service'
        INGRESS_NAME = 'my-app-ingress'
    }

    stages {
        stage('📦 Checkout') {
            steps {
                git 'https://github.com/villeog/microservices-ingress-kastro.git'
            }
        }

        stage('🐳 Build Docker Image') {
            steps {
                sh '''
                docker build -t $IMAGE_NAME:$TAG .
                docker tag $IMAGE_NAME:$TAG $IMAGE_NAME:latest
                '''
            }
        }

        stage('🚀 Push to DockerHub') {
            steps {
                sh '''
                echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                docker push $IMAGE_NAME:$TAG
                docker push $IMAGE_NAME:latest
                '''
            }
        }

        stage('🔧 Configure Local Kubectl') {
            steps {
                withEnv(["KUBECONFIG=$KUBECONFIG"]) {
                    sh '''
                    kubectl config current-context
                    kubectl get nodes -o wide
                    '''
                }
            }
        }

        stage('📤 Deploy to Local Kubernetes') {
            steps {
                withEnv(["KUBECONFIG=$KUBECONFIG"]) {
                    sh '''
                    sed -i "s|image: .*|image: $IMAGE_NAME:$TAG|g" k8s/deployment.yaml
                    kubectl apply -f k8s/deployment.yaml
                    kubectl rollout status deployment/$DEPLOYMENT_NAME --timeout=300s
                    kubectl get pods -l app=my-app
                    kubectl get svc $SERVICE_NAME
                    '''
                }
            }
        }

        stage('🌐 Deploy Ingress') {
            steps {
                withEnv(["KUBECONFIG=$KUBECONFIG"]) {
                    sh '''
                    kubectl apply -f k8s/ingress.yaml
                    sleep 10
                    kubectl get ingress $INGRESS_NAME
                    kubectl describe ingress $INGRESS_NAME
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment succeeded!'
        }
        failure {
            echo '❌ Deployment failed. Check logs above.'
        }
        always {
            echo '📁 Pipeline execution complete.'
        }
    }
}
