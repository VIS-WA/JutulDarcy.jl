import { defineUserConfig } from 'vitepress-export-pdf'
export default defineUserConfig({
  outFile: 'JutulDarcy-docs.pdf',
  pdfOptions: { format: 'A4', printBackground: true, margin: { top: '12mm', bottom: '12mm' } },
  // List routes in reading order to avoid alphabetical crawl
  include: [
    '/', '/man/intro', '/man/first_ex',
    '/man/highlevel', '/man/basics/input_files', '/man/basics/systems',
    '/man/basics/solution', '/man/basics/forces', '/man/basics/wells',
    '/man/basics/primary', '/man/basics/secondary', '/man/basics/parameters',
    '/man/basics/plotting', '/man/basics/utilities',
    '/man/advanced/mpi', '/man/advanced/gpu', '/man/advanced/compiled',
    '/man/basics/package', '/ref/jutul', '/extras/refs'
  ]
})
