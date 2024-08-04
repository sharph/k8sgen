<script lang="ts">
	import yaml from 'js-yaml';
	import Highlight from 'svelte-highlight';
	import { yaml as yamlLang } from 'svelte-highlight/languages/yaml';
	import type { Deployment } from 'kubernetes-types/apps/v1';
	import type { Container, EnvVar } from 'kubernetes-types/core/v1';
	let appName = '';
	let appNamePlaceholder = 'nginx';
	let imagePlaceholder = 'nginx:latest';
	let replicas: string | number = '';
	let yamlStr = '';
	type ContainerConfig = {
		name: string;
		image: string;
		ports: (number | string)[];
		environment: string;
	};
	const emptyContainer: ContainerConfig = {
		name: '',
		image: '',
		ports: [],
		environment: ''
	};
	let containers: ContainerConfig[] = [
		{
			name: '',
			image: '',
			ports: [80],
			environment: ''
		}
	];

	function enforceNumber(num: number | string) {
		return (typeof num == 'string' && isFinite(parseInt(num as string))) ||
			(typeof num == 'number' && isFinite(num))
			? parseInt(num as string)
			: '';
	}

	function numberOnly<T>(num: number | string, defaultValue: T): number | T {
		return (typeof num == 'string' && isFinite(parseInt(num as string))) ||
			(typeof num == 'number' && isFinite(num))
			? parseInt(num as string)
			: defaultValue;
	}

	function environmentStringToEnvVars(environment: string): EnvVar[] {
		return environment
			.split('\n')
			.map((v) => v.split('=', 2))
			.filter((v) => v.length === 2)
			.map(([k, value]) => ({ name: k.split(' '), value }))
			.map(({ name, value }) => ({ name: name[name.length - 1], value }));
	}

	function containerConfigToSpecTemplate(container: ContainerConfig, first: boolean): Container {
		let name = first ? container.name || appName || appNamePlaceholder : container.name;
		let image = container.image || imagePlaceholder;
		const k8scontainer: Container = {
			name,
			image,
			ports: undefined,
			env: environmentStringToEnvVars(container.environment)
		};
		if (container.ports.length > 0) {
			k8scontainer.ports = container.ports.map((p) => ({ containerPort: numberOnly(p, 0) }));
		}
		if (k8scontainer.env?.length === 0) {
			delete k8scontainer.env;
		}
		return k8scontainer;
	}

	function buildYaml() {
		let deployment: Deployment = {
			apiVersion: 'apps/v1',
			kind: 'Deployment',
			metadata: {
				name: appName || appNamePlaceholder,
				labels: {
					app: appName || appNamePlaceholder
				}
			},
			spec: {
				replicas: numberOnly(replicas, undefined),
				selector: {
					matchLabels: {
						app: appName || appNamePlaceholder
					}
				},
				template: {
					metadata: {
						labels: { app: appName || appNamePlaceholder }
					},
					spec: {
						containers: containers.map((container, i) =>
							containerConfigToSpecTemplate(container, i === 0)
						)
					}
				}
			}
		};
		if (deployment.spec?.replicas === 1) {
			delete deployment.spec.replicas;
		}
		yamlStr = yaml.dump(deployment);
	}

	$: {
		appName;
		replicas = enforceNumber(replicas);
		containers.forEach((container) => {
			container.ports = container.ports.map(enforceNumber);
		});
		buildYaml();
	}
</script>

<div class="flex w-full h-full">
	<div class="deployment m-8 flex-auto">
		<label class="label">
			<span>Name</span>
			<input
				class="input"
				type="text"
				placeholder={appNamePlaceholder}
				name="name"
				bind:value={appName}
			/>
		</label>
		<label class="label">
			<span>Replicas</span>
			<input class="input" type="text" placeholder="1" name="name" bind:value={replicas} />
		</label>
		{#each containers as container, container_idx}
			<div class="k-container card p-4 mt-4 mb-4">
				<h2>Container</h2>
				{#if containers.length > 1}
					<label class="label">
						<span>Name</span>
						<input
							class="input"
							type="text"
							placeholder={container_idx === 0 ? appName || appNamePlaceholder : undefined}
							bind:value={container.name}
						/>
					</label>
				{/if}
				<label class="label">
					<span>Image</span>
					<input
						class="input"
						type="text"
						placeholder={imagePlaceholder}
						name="image"
						bind:value={container.image}
					/>
				</label>
				{#each container.ports as port, idx}
					<label class="label flex items-center">
						<span class="flex-none label">Port #{idx + 1}</span>
						<input class="input grow" type="text" bind:value={port} />
						<button
							type="button"
							class="btn variant-filled flex-none"
							on:click={() =>
								(container.ports = [
									...container.ports.slice(0, idx),
									...container.ports.slice(idx + 1)
								])}>Remove</button
						>
					</label>
				{/each}
				<button
					type="button"
					class="btn variant-filled flex-none"
					on:click={() => (container.ports = [...container.ports, 80])}>Add port</button
				>
				<label class="label">
					<span>Environment</span>
					<textarea
						class="textarea"
						rows="10"
						placeholder="KEY=VALUE
KEY2=VALUE
..."
						bind:value={container.environment}
					/>
				</label>
				{#if container_idx > 0}
					<button
						type="button"
						class="btn variant-filled flex-none"
						on:click={() =>
							(containers = [
								...containers.slice(0, container_idx),
								...containers.slice(container_idx + 1)
							])}>Remove container</button
					>
				{/if}
			</div>
		{/each}
		<button
			type="button"
			class="btn variant-filled flex-none"
			on:click={() => (containers = [...containers, { ...emptyContainer }])}>Add container</button
		>
	</div>
	<div class="w-1/2">
		<div class="sticky m-8 top-8">
			<button
				type="button"
				class="btn variant-filled"
				on:click={() => navigator.clipboard.writeText(yamlStr)}>Copy to clipboard</button
			>
			<Highlight language={yamlLang} code={yamlStr} />
		</div>
	</div>
</div>
