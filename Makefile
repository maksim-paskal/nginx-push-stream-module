KUBECONFIG=$(HOME)/.kube/dev
tag=dev
image=paskalmaksim/nginx-push-stream-module:$(tag)

build:
	docker buildx build --platform=linux/amd64,linux/arm64 --pull --push . -t $(image)
run:
	docker run -it -u 30000 --rm -p 8000:8000 $(image)
deploy:
	helm uninstall comet -n nginx-push-stream-module || true
	helm upgrade comet ./charts/nginx-push-stream-module \
	--install \
	--create-namespace \
	--namespace nginx-push-stream-module \
	--set fullname=comet \
	--set replicas=3 \
	--set leaderElection.enabled=true
clean:
	helm uninstall comet -n nginx-push-stream-module || true
	kubectl delete ns nginx-push-stream-module || true
lint:
	ct lint --all
scan:
	trivy image \
	--ignore-unfixed --no-progress --severity HIGH,CRITICAL \
	$(image)
publish:
	make build tag=$(shell git rev-parse --short HEAD)