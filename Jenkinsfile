pipeline {
    agent any

    environment {
        DOCKER_HUB_REPO = 'villers118/techsolutions-app'
        KUBECONFIG = '/home/cr/.kube/config'
        NAMESPACE = 'default'
        APP_NAME = 'techsolutions'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out sourcecode'
                git branch: 'feature/my-new-feature',
                    url: 'https://github.com/villeog/microservices-ingress-kastro.git'
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
                    echo "Current context verified"
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
