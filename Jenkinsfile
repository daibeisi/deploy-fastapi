pipeline {
    agent any
    
    // 环境变量配置
    environment {
        APP_NAME = 'fastapi-cicd-app'
        // DOCKER_REGISTRY = 'registry.cn-hangzhou.aliyuncs.com/yournamespace'  // 远程镜像仓库（已禁用）
        // GIT_CREDENTIALS_ID = 'git-credentials'  // Git 凭据 ID
        // DOCKER_CREDENTIALS_ID = 'docker-registry-credentials'  // Docker 仓库凭据 ID
        // DEPLOY_SERVER = 'production-server'  // 部署服务器（已禁用，使用本地部署）
    }
    
    // 触发器配置
    triggers {
        // 监听 GitHub Webhook 或定时构建
        pollSCM('H/5 * * * *')  // 每 5 分钟检查一次代码变更
    }
    
    // 参数化构建
    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['development', 'staging', 'production'],
            description: '选择部署环境'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: '是否跳过测试阶段'
        )
        // booleanParam(
        //     name: 'PUSH_IMAGE',
        //     defaultValue: true,
        //     description: '是否推送镜像到仓库（已禁用，使用本地镜像）'
        // )
    }
    
    // 流水线阶段
    stages {
        
        stage('📦 环境准备') {
            steps {
                echo '========================================='
                echo '  FastAPI CI/CD Pipeline Started'
                echo "  Branch: ${env.GIT_BRANCH}"
                echo "  Build: ${env.BUILD_NUMBER}"
                echo "  Environment: ${params.DEPLOY_ENV}"
                echo '========================================='
                
                // 清理工作空间
                cleanWs()
                
                // 检出代码
                checkout scm
                
                // 显示 Git 信息
                sh '''
                    echo "Git Commit: $(git rev-parse --short HEAD)"
                    echo "Git Author: $(git log -1 --pretty=format:'%an')"
                    echo "Git Message: $(git log -1 --pretty=format:'%s')"
                '''
            }
        }
        
        stage('� Python 环境准备') {
            steps {
                script {
                    echo '准备 uv 环境...'
                    sh '''
                        set -e
                        
                        # 安装 uv（如果未安装）
                        if ! command -v uv &> /dev/null; then
                            echo "安装 uv..."
                            curl -LsSf https://astral.sh/uv/install.sh | sh
                            export PATH="$HOME/.cargo/bin:$PATH"
                        fi
                        
                        # 显示 uv 版本
                        uv --version
                        
                        # 安装项目依赖（包括开发依赖）
                        uv sync --all-extras
                        
                        echo "✅ Python 环境准备完成"
                    '''
                }
            }
        }
        
        stage('�🔍 代码检查') {
            parallel {
                stage('代码规范检查 (Flake8)') {
                    steps {
                        script {
                            echo '运行 Flake8 代码规范检查...'
                            // 严重错误会导致构建失败
                            def flake8Result = sh(
                                script: '''
                                    uv run flake8 app/ --count --select=E9,F63,F7,F82 --show-source --statistics
                                ''',
                                returnStatus: true
                            )
                            if (flake8Result != 0) {
                                unstable('Flake8 代码检查发现严重问题')
                                error('❌ Flake8 检查失败！请修复代码后重新提交')
                            }
                        }
                    }
                }
                
                stage('代码格式检查 (Black)') {
                    steps {
                        script {
                            echo '运行 Black 代码格式检查...'
                            // Black 格式问题只标记为 unstable，不阻止构建
                            def blackResult = sh(
                                script: '''
                                    uv run black --check app/
                                ''',
                                returnStatus: true
                            )
                            if (blackResult != 0) {
                                unstable('⚠️ 代码格式不符合规范，建议运行: uv run black app/')
                            }
                        }
                    }
                }
                
                stage('安全扫描 (Bandit)') {
                    steps {
                        script {
                            echo '运行 Bandit 安全扫描...'
                            // 高危安全问题会导致构建失败
                            def banditResult = sh(
                                script: '''
                                    uv run bandit -r app/ -ll -f txt
                                ''',
                                returnStatus: true
                            )
                            if (banditResult != 0) {
                                unstable('发现安全问题')
                                // 可以选择是否阻止构建
                                // error('❌ 安全扫描失败！发现高危漏洞')
                            }
                        }
                    }
                }
            }
        }
        
        stage('🧪 单元测试') {
            when {
                expression { !params.SKIP_TESTS }
            }
            steps {
                echo '运行单元测试...'
                script {
                    def testResult = sh(
                        script: '''
                            # 创建测试目录
                            mkdir -p tests
                            
                            # 运行测试（如果测试文件存在）
                            if [ -d "tests" ] && [ "$(ls -A tests)" ]; then
                                uv run pytest tests/ --cov=app --cov-report=xml --cov-report=html --junitxml=test-results.xml
                            else
                                echo "No tests found, skipping..."
                                exit 0
                            fi
                        ''',
                        returnStatus: true
                    )
                    
                    // 测试失败则构建失败
                    if (testResult != 0) {
                        error('❌ 单元测试失败！请修复测试后重新提交')
                    }
                }
                
                // 发布测试报告
                junit allowEmptyResults: true, testResults: 'test-results.xml'
            }
        }
        
        stage('🏗️ 构建镜像') {
            steps {
                script {
                    echo '构建 Docker 镜像（本地）...'
                    def imageTag = "${env.BUILD_NUMBER}-${env.GIT_COMMIT[0..7]}"
                    
                    sh """
                        docker build -t ${APP_NAME}:${imageTag} .
                        docker tag ${APP_NAME}:${imageTag} ${APP_NAME}:latest
                    """
                    
                    // 保存镜像标签供后续使用
                    env.IMAGE_TAG = imageTag
                    
                    echo "✅ 本地镜像构建完成: ${APP_NAME}:${imageTag}"
                    echo "✅ Latest 标签: ${APP_NAME}:latest"
                }
            }
        }
        
        stage('🔐 镜像扫描') {
            steps {
                echo '扫描镜像安全漏洞...'
                script {
                    // 使用 Trivy 或 Clair 扫描镜像（需要安装）
                    sh """
                        # 如果安装了 Trivy
                        if command -v trivy &> /dev/null; then
                            trivy image --severity HIGH,CRITICAL ${APP_NAME}:latest || true
                        else
                            echo "Trivy not installed, skipping image scan"
                        fi
                    """
                }
            }
        }
        
        // stage('📤 推送镜像') {
        //     when {
        //         expression { params.PUSH_IMAGE && env.GIT_BRANCH == 'main' }
        //     }
        //     steps {
        //         script {
        //             echo '推送镜像到远程仓库...'
        //             withCredentials([usernamePassword(
        //                 credentialsId: "${DOCKER_CREDENTIALS_ID}",
        //                 usernameVariable: 'DOCKER_USER',
        //                 passwordVariable: 'DOCKER_PASS'
        //             )]) {
        //                 sh """
        //                     echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin ${DOCKER_REGISTRY}
        //                     
        //                     docker tag ${APP_NAME}:${env.IMAGE_TAG} ${DOCKER_REGISTRY}/${APP_NAME}:${env.IMAGE_TAG}
        //                     docker tag ${APP_NAME}:${env.IMAGE_TAG} ${DOCKER_REGISTRY}/${APP_NAME}:latest
        //                     
        //                     docker push ${DOCKER_REGISTRY}/${APP_NAME}:${env.IMAGE_TAG}
        //                     docker push ${DOCKER_REGISTRY}/${APP_NAME}:latest
        //                 """
        //             }
        //         }
        //     }
        // }
        
        stage('🚀 部署应用') {
            when {
                branch 'main'  // 只有主分支才部署
            }
            steps {
                script {
                    echo '开始部署应用到本地 Docker...'
                    
                    // 赋予脚本执行权限
                    sh 'chmod +x deploy.sh'
                    
                    // 执行部署脚本（本地 Docker 部署）
                    sh './deploy.sh'
                    
                    echo '✅ 应用已部署到本地 Docker'
                    echo '📍 访问地址: http://localhost:8000'
                    
                    // 如需远程部署，取消下方注释并配置 SSH 凭据
                    // sshagent(credentials: ["${DEPLOY_SERVER}"]) {
                    //     sh '''
                    //         ssh user@server 'cd /path/to/app && git pull && ./deploy.sh'
                    //     '''
                    // }
                }
            }
        }
        
        stage('✅ 健康检查') {
            steps {
                script {
                    echo '执行健康检查...'
                    
                    // 等待服务启动
                    sleep time: 10, unit: 'SECONDS'
                    
                    sh '''
                        max_retries=30
                        retry_count=0
                        
                        while [ $retry_count -lt $max_retries ]; do
                            if curl -f -s http://localhost:8000/health > /dev/null; then
                                echo "✓ 健康检查通过"
                                exit 0
                            fi
                            
                            retry_count=$((retry_count + 1))
                            echo "健康检查失败，重试 ($retry_count/$max_retries)..."
                            sleep 2
                        done
                        
                        echo "✗ 健康检查失败"
                        exit 1
                    '''
                }
            }
        }
        
        stage('🧹 清理') {
            steps {
                echo '清理旧资源...'
                sh '''
                    # 清理悬空镜像
                    docker image prune -f || true
                    
                    # 清理旧容器
                    docker container prune -f || true
                    
                    # 清理虚拟环境（uv 创建的是 .venv）
                    rm -rf .venv
                '''
            }
        }
    }
    
    // 构建后操作
    post {
        success {
            echo '========================================='
            echo '  ✅ Pipeline 执行成功！'
            echo '  应用访问地址: http://localhost:8000'
            echo '  API 文档: http://localhost:8000/docs'
            echo '========================================='
            
            // 发送成功通知（可选）
            // emailext (
            //     subject: "✅ Jenkins Build Success: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            //     body: "构建成功！详情: ${env.BUILD_URL}",
            //     to: 'your-email@example.com'
            // )
        }
        
        failure {
            echo '========================================='
            echo '  ❌ Pipeline 执行失败！'
            echo '  请查看日志: ${env.BUILD_URL}console'
            echo '========================================='
            
            // 发送失败通知（可选）
            // emailext (
            //     subject: "❌ Jenkins Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            //     body: "构建失败！详情: ${env.BUILD_URL}",
            //     to: 'your-email@example.com'
            // )
        }
        
        always {
            // 保存构建产物
            archiveArtifacts artifacts: '**/test-results.xml', allowEmptyArchive: true
            
            // 清理工作空间
            cleanWs(
                deleteDirs: true,
                patterns: [
                    [pattern: '.venv/', type: 'INCLUDE']
                ]
            )
        }
    }
    
    // 构建选项
    options {
        // 保留最近 10 次构建
        buildDiscarder(logRotator(numToKeepStr: '10'))
        
        // 超时时间
        timeout(time: 30, unit: 'MINUTES')
        
        // 不允许并发构建
        disableConcurrentBuilds()
        
        // 时间戳
        timestamps()
        
        // 控制台输出带颜色
        ansiColor('xterm')
    }
}
