kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl edit svc argocd-server -n argocd
#change to NodePort
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath={.data.password} | base64 -d
 argocd app create demo-app \
 	--repo https://github.com/sajil143pb/jenkins.git \
 	--path java_eks_helm_argo/Argocd/myapp \
 	--dest-server https://kubernetes.default.svc \
 	--dest-namespace demo-app \
 	--sync-option CreateNamespace=true \
	--parameter namespace=demo-app \
 application 'demo-app' created