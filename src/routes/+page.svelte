<script lang="ts">
	import yaml from 'js-yaml';
	import Highlight from 'svelte-highlight';
	import { yaml as yamlLang } from 'svelte-highlight/languages/yaml';
	let appName = '';
	let appNamePlaceholder = 'nginx';
	let imagePlaceholder = 'nginx:latest';
	let replicas: string | number = '';
	let yamlStr = '';
	type Container = {
		image: string;
		ports: (number | string)[];
	};
	const emptyContainer = {
		image: '',
		ports: []
	};
	let containers: Container[] = [
		{
			image: '',
			ports: [80]
		}
	];

	function enforceNumber(num: number | string) {
		return (typeof num == 'string' && isFinite(parseInt(num as string))) ||
			(typeof num == 'number' && isFinite(num))
			? parseInt(num as string)
			: '';
	}

	function buildYaml() {
		let resource: any = {
			apiVersion: 'apps/v1',
			kind: 'Deployment',
			metadata: {
				name: appName || appNamePlaceholder,
				labels: {
					app: appName || appNamePlaceholder
				}
			},
			spec: {
				replicas,
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
						containers: containers.map((container) => ({
							name: appName || appNamePlaceholder,
							image: container.image || imagePlaceholder,
							ports: container.ports.map((p) => ({
								containerPort: p
							}))
						}))
					}
				}
			}
		};
		if (resource.spec.replicas === 1 || resource.spec.replicas === '') {
			delete resource.spec['replicas'];
		}
		yamlStr = yaml.dump(resource);
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

<div class="deployment m-8">
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
<button
	type="button"
	class="btn variant-filled"
	on:click={() => navigator.clipboard.writeText(yamlStr)}>Copy to clipboard</button
>
<Highlight language={yamlLang} code={yamlStr} />
