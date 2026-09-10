import {defineConfig} from '@playwright/test';
export default defineConfig({testDir:'.',testMatch:'native.spec.ts',workers:1,timeout:570000,outputDir:'output/native',projects:[{name:'android'},{name:'ios'}]});
