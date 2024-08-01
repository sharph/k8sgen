<script lang="ts">
	import yaml from 'js-yaml';
	import Highlight from 'svelte-highlight';
	import { yaml as yamlLang } from 'svelte-highlight/languages/yaml';
	let appName = '';
	let appNamePlaceholder = 'nginx';
	let image = '';
	let imagePlaceholder = 'nginx:latest';
	let yamlStr = 'HELLO';

	function buildYaml() {
		let resource = {
			apiVersion: 'apps/v1',
			kind: 'Deployment',
			metadata: {
				name: 'nginx-deployment',
				labels: {
					app: 'nginx'
				}
			},
			spec: {
				replicas: 3,
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
						containers: [
							{
								name: appName || appNamePlaceholder,
								image: image || imagePlaceholder,
								ports: [{ containerPort: 80 }]
							}
						]
					}
				}
			}
		};
		yamlStr = yaml.dump(resource);
	}

	$: {
		appName;
		image;
		buildYaml();
	}
</script>

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
	<span>Image</span>
	<input class="input" type="text" placeholder={imagePlaceholder} name="image" bind:value={image} />
</label>
<button type="button" class="btn variant-filled">Copy to clipboard</button>
<Highlight language={yamlLang} code={yamlStr} />
