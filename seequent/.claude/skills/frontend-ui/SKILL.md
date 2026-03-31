---
name: frontend-ui
description: UI component, layout, styling, and feedback conventions. Use when working with MUI, tss-react, icons, notifications, or building React components.
---

# Frontend UI Guide

This skill defines how UI components, layout, styling, icons, and user feedback work in this application.

## Technology Stack

| Purpose        | Technology                         | Usage                                      |
| -------------- | ---------------------------------- | ------------------------------------------ |
| Components     | MUI v7 (`@mui/material`)           | All UI components — buttons, inputs, cards |
| Styling        | Emotion + tss-react                | Component-scoped styles and theming        |
| Icons          | `@mui/icons-material`              | All icons                                  |
| Notifications  | notistack                          | Toasts and snackbars                       |

---

## MUI Component Conventions

### Layout

Use MUI layout primitives — avoid raw `div` elements for structural layout:

| Need                    | Use              | Avoid            |
| ----------------------- | ---------------- | ---------------- |
| Flex container          | `Stack`          | `<div style={{display:'flex'}}>` |
| Generic container/box   | `Box`            | `<div>`          |
| Responsive grid         | `Grid2`          | Custom CSS grid  |
| Full-page layout        | `Box` + `Stack`  | nested `div`s    |

```typescript
// Horizontal row with spacing
<Stack direction="row" spacing={2} alignItems="center">
  <Button>Cancel</Button>
  <Button variant="contained">Save</Button>
</Stack>

// Responsive grid
<Grid2 container spacing={2}>
  <Grid2 size={{ xs: 12, md: 6 }}>
    <ItemCard />
  </Grid2>
</Grid2>
```

### Buttons

```typescript
// Primary action
<Button variant="contained" onClick={handleSave}>Save</Button>

// Secondary / cancel
<Button variant="outlined" onClick={handleCancel}>Cancel</Button>

// Destructive
<Button variant="contained" color="error" onClick={handleDelete}>Delete</Button>

// Icon button
<IconButton aria-label="edit" onClick={handleEdit}>
  <EditIcon />
</IconButton>
```

### Dialogs

```typescript
<Dialog open={isOpen} onClose={handleClose} maxWidth="sm" fullWidth>
  <DialogTitle>Confirm Action</DialogTitle>
  <DialogContent>
    <DialogContentText>Are you sure?</DialogContentText>
  </DialogContent>
  <DialogActions>
    <Button onClick={handleClose}>Cancel</Button>
    <Button variant="contained" onClick={handleConfirm}>Confirm</Button>
  </DialogActions>
</Dialog>
```

### Loading and Error States

Always handle loading and error states explicitly:

```typescript
const { data, isLoading, isError } = useGetItemsQuery()

if (isLoading) return <CircularProgress />
if (isError) return <Alert severity="error">Failed to load items.</Alert>
```

For skeleton loading (preferred for content-heavy views):

```typescript
if (isLoading) return <Skeleton variant="rectangular" height={200} />
```

---

## Styling

### tss-react (`makeStyles`) — component-scoped styles

Use for any component that needs more than one or two style rules:

```typescript
import { makeStyles } from 'tss-react/mui'

const useStyles = makeStyles()((theme) => ({
  root: {
    padding: theme.spacing(2),
    borderRadius: theme.shape.borderRadius,
    backgroundColor: theme.palette.background.paper,
  },
  title: {
    fontWeight: theme.typography.fontWeightBold,
    marginBottom: theme.spacing(1),
  },
}))

function MyComponent() {
  const { classes } = useStyles()
  return (
    <Box className={classes.root}>
      <Typography className={classes.title}>Title</Typography>
    </Box>
  )
}
```

### `sx` prop — one-off overrides

Use for single-property tweaks that don't warrant a `makeStyles` entry:

```typescript
<Box sx={{ mt: 2, mb: 1 }}>
<Typography sx={{ color: 'text.secondary' }}>
```

### Rules

| Situation                       | Use                  |
| ------------------------------- | -------------------- |
| Component needs multiple styles | `makeStyles`         |
| One or two quick overrides      | `sx` prop            |
| Dynamic styles based on props   | `makeStyles` with params |
| Never use                       | Inline `style={{}}` objects |

### Theme Tokens

Always use theme values — never hardcode colours, spacing, or typography:

```typescript
// DO
backgroundColor: theme.palette.primary.main
padding: theme.spacing(2)
fontWeight: theme.typography.fontWeightBold

// DON'T
backgroundColor: '#1976d2'
padding: '16px'
fontWeight: 700
```

---

## Icons

Always import from `@mui/icons-material`. Never add a separate icon library.

```typescript
import EditIcon from '@mui/icons-material/Edit'
import DeleteIcon from '@mui/icons-material/Delete'
import AddIcon from '@mui/icons-material/Add'
import CloseIcon from '@mui/icons-material/Close'

// In a button
<Button startIcon={<AddIcon />}>Add Item</Button>

// Standalone
<IconButton aria-label="delete">
  <DeleteIcon />
</IconButton>
```

Icon sizing follows MUI defaults (`fontSize="small" | "medium" | "large"`). Don't set custom `width`/`height` on icons.

---

## Notifications (notistack)

Use `notistack` for all toast/snackbar feedback. Never build custom snackbar components.

```typescript
import { useSnackbar } from 'notistack'

function MyComponent() {
  const { enqueueSnackbar } = useSnackbar()

  const handleSave = async () => {
    try {
      await saveItem(data)
      enqueueSnackbar('Item saved successfully', { variant: 'success' })
    } catch {
      enqueueSnackbar('Failed to save item', { variant: 'error' })
    }
  }
}
```

| Variant     | When to use                          |
| ----------- | ------------------------------------ |
| `success`   | Mutation completed successfully      |
| `error`     | Mutation or load failed              |
| `warning`   | Non-blocking issue the user should know |
| `info`      | Neutral status update                |

---

## Form UI — MUI + React Hook Form

Wire MUI inputs to React Hook Form (see `frontend-data-management` skill for schema/validation):

```typescript
import { useForm, Controller } from 'react-hook-form'
import { TextField, Select, MenuItem, FormControl, InputLabel, FormHelperText } from '@mui/material'

// TextField — use register directly
<TextField
  {...register('name')}
  label="Name"
  error={!!errors.name}
  helperText={errors.name?.message}
  fullWidth
/>

// Select — use Controller wrapper
<Controller
  name="type"
  control={control}
  render={({ field }) => (
    <FormControl error={!!errors.type} fullWidth>
      <InputLabel>Type</InputLabel>
      <Select {...field} label="Type">
        <MenuItem value="a">Option A</MenuItem>
        <MenuItem value="b">Option B</MenuItem>
      </Select>
      {errors.type && <FormHelperText>{errors.type.message}</FormHelperText>}
    </FormControl>
  )}
/>
```

---

## Typography

```typescript
<Typography variant="h4">Page Title</Typography>
<Typography variant="h6">Section Heading</Typography>
<Typography variant="body1">Main body text</Typography>
<Typography variant="body2" color="text.secondary">Secondary / caption text</Typography>
<Typography variant="caption">Small label</Typography>
```

Never use raw `<h1>`–`<h6>` or `<p>` — always use MUI `Typography`.

---

## Anti-Patterns to Avoid

```typescript
// DON'T: Raw div for layout
<div style={{ display: 'flex', gap: '16px' }}>

// DO: MUI Stack
<Stack direction="row" spacing={2}>

// DON'T: Hardcoded colours
<Box sx={{ color: '#666' }}>

// DO: Theme token
<Box sx={{ color: 'text.secondary' }}>

// DON'T: Inline style objects
<Typography style={{ marginTop: 8 }}>

// DO: sx prop
<Typography sx={{ mt: 1 }}>

// DON'T: Custom icon libraries (no iconsax, heroicons etc.)
import { Edit } from 'iconsax-react'

// DO: MUI icons
import EditIcon from '@mui/icons-material/Edit'

// DON'T: Custom snackbar/toast components
<Snackbar open={...} message="Saved" />

// DO: notistack
enqueueSnackbar('Saved', { variant: 'success' })
```
