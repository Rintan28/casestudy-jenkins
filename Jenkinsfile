pipeline {
  agent any

  environment {
    IMAGE = "eve56/demo-app"
    TAG = "latest"
    DOCKER_CRED = "docker-hub"
    KUBECONFIG_CRED = "kubeconfig-dev"
    NAMESPACE = "default"
    HELM_RELEASE = "casestudy-jenkins1"
  }

  stages {
    stage('Checkout Source Code') {
      steps {
        git url: 'https://github.com/Rintan28/casestudy-jenkins.git', branch: 'main'
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          echo "🛠️ Building image ${IMAGE}:${TAG}..."
          // Cek isi workspace
          sh 'pwd'
          sh 'ls -la'

          // Pastikan kita di direktori yang punya Dockerfile & .dockerignore
          dir('.') {
            def builtImage = docker.build("${IMAGE}:${TAG}", '.')
          }
        }
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: "docker-hub",
          usernameVariable: 'USER',
          passwordVariable: 'PASS'
        )]) {
          script {
            echo "📦 Pushing image to DockerHub..."
            sh """
              echo "$PASS" | docker login -u "$USER" --password-stdin
              docker push ${IMAGE}:${TAG}
            """
          }
        }
      }
    }

    stage('Deploy to Kubernetes') {
      agent {
        docker {
          image 'alpine/helm:latest'
          args '-u root:root'
        }
      }
      steps {
        script {
          git url: 'https://github.com/Rintan28/casestudy-jenkins.git', branch: 'main'

          withCredentials([file(credentialsId: "${KUBECONFIG_CRED}", variable: 'KUBECONFIG_FILE')]) {
            echo "🚀 Deploying to Kubernetes via Helm..."
            sh '''
                # Install kubectl
                apk add --no-cache curl
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                chmod +x kubectl
                mv kubectl /usr/local/bin/
                    
                 # Debug environment variables
                echo "=== DEBUG INFO ==="
                echo "KUBECONFIG_CRED = ${KUBECONFIG_CRED}"
                echo "KUBECONFIG_FILE = $KUBECONFIG_FILE"
                echo "PWD = $(pwd)"
                echo "HOME = $HOME"
                echo ""
                    
                # Check if kubeconfig file exists
                if [ -z "$KUBECONFIG_FILE" ]; then
                    echo "❌ ERROR: KUBECONFIG_FILE variable is empty"
                    echo "Check if credential '${KUBECONFIG_CRED}' exists in Jenkins"
                    exit 1
                fi
                    
                if [ ! -f "$KUBECONFIG_FILE" ]; then
                    echo "❌ ERROR: Kubeconfig file not found at: $KUBECONFIG_FILE"
                    ls -la $(dirname "$KUBECONFIG_FILE") || echo "Directory not found"
                    exit 1
                fi
                    
                echo "✅ Kubeconfig file found: $KUBECONFIG_FILE"
                echo "File size: $(wc -c < "$KUBECONFIG_FILE") bytes"
                    
                # Setup kubeconfig
                mkdir -p ~/.kube
                cp "$KUBECONFIG_FILE" ~/.kube/config
                chmod 600 ~/.kube/config
                    
                echo "🔍 Testing Kubernetes connection..."
                kubectl cluster-info
                kubectl get nodes
                    
                echo "📋 Helm chart validation..."
                helm lint ./helm
                    
                echo "🚀 Deploying application..."
                helm upgrade --install $HELM_RELEASE ./helm \
                    --set image.repository=$IMAGE \
                    --set image.tag=$TAG \
                    --namespace $NAMESPACE \
                    --create-namespace \
                    --wait \
                    --timeout=300s \
                    --debug
                    
                echo "✅ Deployment completed!"
            '''
          }
        }
      }
    }
  }


  post {
    success {
      echo "✅ Pipeline Sukses: Aplikasi berhasil dideploy ke Kubernetes"
    }
    failure {
      echo "❌ Pipeline Gagal: Cek log untuk mengetahui error"
    }
  }
}
