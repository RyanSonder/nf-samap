run:
	nextflow run main.nf 

docker:
	docker build -f docker/bash/Dockerfile -t pipeline/bash:latest .
	docker build -f docker/blast/Dockerfile -t pipeline/blast:latest .
	docker build -f docker/samap/Dockerfile -t pipeline/samap:latest .
	docker build -f docker/seurat/Dockerfile -t pipeline/seurat:latest .

docker-shell-samap:
	docker run --rm -it \
		-v $(PWD):/workspace \
		-w /workspace \
		--entrypoint /bin/bash \
		pipeline/samap:latest

docker-shell-blast:
	docker run --rm -it \
		-v $(PWD):/workspace \
		-w /workspace \
		--entrypoint /bin/bash \
		pipeline/samap-blast:latest

clean:
	rm -rf work/*
	rm -rf .nextflow*
	rm -rf out/*